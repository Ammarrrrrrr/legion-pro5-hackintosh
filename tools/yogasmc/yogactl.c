// yogactl - talk to YogaSMC (Legion build) from the shell, no root needed.
//
//   yogactl props [class]                      print properties (default IdeaWMIGameZone)
//   yogactl set <class> <key> <value>          value: true/false, number (dec or 0x), or string
//   yogactl mode [quiet|balanced|performance|custom]   show or set the Fn+Q power mode
//   yogactl sensors                            read fan/temperature sensors once
//   yogactl probe                              run every read-only Game Zone / capability getter
//   yogactl query <gamezone|other|lighting|fan> <method> [arg|none]   read-only WMI method call
//   yogactl block <guid> [instance]            read a WMI data block
//   yogactl acpi <TABLE> [instance] <out.aml>  dump an ACPI table (DSDT, SSDT, ...)
//
// Build: clang -O2 -framework IOKit -framework CoreFoundation -o yogactl yogactl.c
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

static io_service_t find(const char *cls) {
    io_service_t s = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(cls));
    if (!s) { fprintf(stderr, "%s not found (is the YogaSMC Legion build loaded?)\n", cls); exit(1); }
    return s;
}

static void print(CFTypeRef v, int indent);

static void printDictEntry(const void *k, const void *v, void *ctx) {
    int indent = *(int *)ctx;
    char key[256] = "";
    CFStringGetCString((CFStringRef)k, key, sizeof(key), kCFStringEncodingUTF8);
    printf("%*s%s = ", indent, "", key);
    print(v, indent);
}

static int cmpKeys(const void *a, const void *b) {
    return CFStringCompare(*(CFStringRef *)a, *(CFStringRef *)b, 0);
}

static void print(CFTypeRef v, int indent) {
    CFTypeID t = CFGetTypeID(v);
    if (t == CFDictionaryGetTypeID()) {
        CFIndex n = CFDictionaryGetCount(v);
        const void **keys = malloc(sizeof(void *) * (n ? n : 1)), **vals = malloc(sizeof(void *) * (n ? n : 1));
        CFDictionaryGetKeysAndValues(v, keys, vals);
        qsort(keys, n, sizeof(void *), cmpKeys);
        printf("{\n");
        int in = indent + 2;
        for (CFIndex i = 0; i < n; i++) printDictEntry(keys[i], CFDictionaryGetValue(v, keys[i]), &in);
        printf("%*s}\n", indent, "");
        free(keys); free(vals);
    } else if (t == CFArrayGetTypeID()) {
        printf("(");
        for (CFIndex i = 0; i < CFArrayGetCount(v); i++) {
            if (i) printf(", ");
            CFTypeRef e = CFArrayGetValueAtIndex(v, i);
            if (CFGetTypeID(e) == CFNumberGetTypeID()) { long long x; CFNumberGetValue(e, kCFNumberLongLongType, &x); printf("%lld", x); }
            else print(e, indent);
        }
        printf(")\n");
    } else if (t == CFNumberGetTypeID()) {
        long long x; CFNumberGetValue(v, kCFNumberLongLongType, &x);
        printf("%lld (0x%llx)\n", x, x);
    } else if (t == CFBooleanGetTypeID()) {
        printf("%s\n", CFBooleanGetValue(v) ? "Yes" : "No");
    } else if (t == CFStringGetTypeID()) {
        char s[1024] = ""; CFStringGetCString(v, s, sizeof(s), kCFStringEncodingUTF8); printf("\"%s\"\n", s);
    } else if (t == CFDataGetTypeID()) {
        CFIndex len = CFDataGetLength(v); const UInt8 *p = CFDataGetBytePtr(v);
        printf("<%ld bytes:", (long)len);
        for (CFIndex i = 0; i < len && i < 64; i++) printf(" %02x", p[i]);
        printf("%s>\n", len > 64 ? " ..." : "");
    } else {
        CFShow(v);
    }
}

static CFTypeRef parseValue(const char *s) {
    if (!strcasecmp(s, "true") || !strcasecmp(s, "yes")) return CFRetain(kCFBooleanTrue);
    if (!strcasecmp(s, "false") || !strcasecmp(s, "no")) return CFRetain(kCFBooleanFalse);
    char *end; long long n = strtoll(s, &end, 0);
    if (*s && !*end) return CFNumberCreate(NULL, kCFNumberLongLongType, &n);
    return CFStringCreateWithCString(NULL, s, kCFStringEncodingUTF8);
}

static void setProp(io_service_t s, const char *key, CFTypeRef value) {
    CFStringRef k = CFStringCreateWithCString(NULL, key, kCFStringEncodingUTF8);
    kern_return_t kr = IORegistryEntrySetCFProperty(s, k, value);
    CFRelease(k);
    if (kr) { fprintf(stderr, "set %s failed: 0x%x\n", key, kr); exit(1); }
}

static CFTypeRef getProp(io_service_t s, const char *key) {
    CFStringRef k = CFStringCreateWithCString(NULL, key, kCFStringEncodingUTF8);
    CFTypeRef v = IORegistryEntryCreateCFProperty(s, k, NULL, 0);
    CFRelease(k);
    return v;
}

static void showProp(io_service_t s, const char *key) {
    CFTypeRef v = getProp(s, key);
    printf("%s = ", key);
    if (v) { print(v, 0); CFRelease(v); } else printf("(none)\n");
}

static CFDictionaryRef dict2(const char *k1, CFTypeRef v1, const char *k2, CFTypeRef v2, const char *k3, CFTypeRef v3) {
    CFMutableDictionaryRef d = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    const char *ks[] = {k1, k2, k3}; CFTypeRef vs[] = {v1, v2, v3};
    for (int i = 0; i < 3; i++) {
        if (!ks[i] || !vs[i]) continue;
        CFStringRef k = CFStringCreateWithCString(NULL, ks[i], kCFStringEncodingUTF8);
        CFDictionarySetValue(d, k, vs[i]); CFRelease(k);
    }
    return d;
}

static void usage(void) {
    fprintf(stderr, "usage: yogactl props [class] | set <class> <key> <value> | mode [name] | sensors | probe\n"
                    "       yogactl query <gamezone|other|lighting|fan> <method> [arg|none] | block <guid> [instance]\n"
                    "       yogactl acpi <TABLE> [instance] <out.aml>\n");
    exit(2);
}

int main(int argc, char **argv) {
    if (argc < 2) usage();
    const char *cmd = argv[1];

    if (!strcmp(cmd, "props")) {
        io_service_t s = find(argc > 2 ? argv[2] : "IdeaWMIGameZone");
        CFMutableDictionaryRef p = NULL;
        IORegistryEntryCreateCFProperties(s, &p, NULL, 0);
        if (p) { CFDictionaryRemoveValue(p, CFSTR("ACPITable")); print(p, 0); CFRelease(p); }
    } else if (!strcmp(cmd, "set") && argc == 5) {
        io_service_t s = find(argv[2]);
        CFTypeRef v = parseValue(argv[4]);
        setProp(s, argv[3], v); CFRelease(v);
        printf("ok\n");
    } else if (!strcmp(cmd, "mode")) {
        io_service_t s = find("IdeaWMIGameZone");
        if (argc > 2) {
            const char *names[] = {"quiet", "balanced", "performance", "custom"}; int vals[] = {1, 2, 3, 255};
            CFTypeRef v = NULL;
            for (int i = 0; i < 4; i++) if (!strcasecmp(argv[2], names[i])) v = CFNumberCreate(NULL, kCFNumberIntType, &vals[i]);
            if (!v) v = parseValue(argv[2]);
            setProp(s, "PowerMode", v); CFRelease(v);
            showProp(s, "PowerModeSetResult");
        }
        setProp(s, "Update", kCFBooleanTrue);
        showProp(s, "PowerMode"); showProp(s, "PowerModeName"); showProp(s, "ThermalMode");
    } else if (!strcmp(cmd, "sensors")) {
        io_service_t s = find("IdeaWMIGameZone");
        setProp(s, "UpdateSensors", kCFBooleanTrue);
        showProp(s, "Legion Sensors"); showProp(s, "Legion Sensor Source");
    } else if (!strcmp(cmd, "probe")) {
        io_service_t s = find("IdeaWMIGameZone");
        setProp(s, "ProbeAll", kCFBooleanTrue);
        showProp(s, "Legion Probe");
    } else if (!strcmp(cmd, "query") && argc >= 4) {
        io_service_t s = find("IdeaWMIGameZone");
        CFStringRef guid = CFStringCreateWithCString(NULL, argv[2], kCFStringEncodingUTF8);
        CFTypeRef method = parseValue(argv[3]);
        CFTypeRef arg = NULL, noArg = NULL;
        if (argc > 4) {
            if (!strcmp(argv[4], "none")) noArg = kCFBooleanTrue;
            else if (!strncmp(argv[4], "hex:", 4)) {
                const char *h = argv[4] + 4; size_t n = strlen(h) / 2; UInt8 *b = malloc(n ? n : 1);
                for (size_t i = 0; i < n; i++) sscanf(h + 2 * i, "%2hhx", &b[i]);
                arg = CFDataCreate(NULL, b, n); free(b);
            } else arg = parseValue(argv[4]);
        }
        CFDictionaryRef req = dict2("GUID", guid, "Method", method, arg ? "Arg" : "NoArg", arg ? arg : noArg);
        setProp(s, "WMIQuery", req);
        showProp(s, "WMIQueryResult");
    } else if (!strcmp(cmd, "block") && argc >= 3) {
        io_service_t s = find("IdeaWMIGameZone");
        CFStringRef guid = CFStringCreateWithCString(NULL, argv[2], kCFStringEncodingUTF8);
        CFTypeRef inst = parseValue(argc > 3 ? argv[3] : "0");
        CFDictionaryRef req = dict2("GUID", guid, "Instance", inst, NULL, NULL);
        setProp(s, "WMIBlock", req);
        showProp(s, "WMIBlockResult");
    } else if (!strcmp(cmd, "acpi") && argc >= 4) {
        io_service_t s = find("IdeaWMIGameZone");
        const char *out = argv[argc - 1];
        CFStringRef table = CFStringCreateWithCString(NULL, argv[2], kCFStringEncodingUTF8);
        CFTypeRef inst = parseValue(argc > 4 ? argv[3] : "0");
        CFDictionaryRef req = dict2("Table", table, "Instance", inst, NULL, NULL);
        setProp(s, "DumpACPI", req);
        showProp(s, "ACPITableName");
        CFTypeRef data = getProp(s, "ACPITable");
        if (!data || CFGetTypeID(data) != CFDataGetTypeID()) { fprintf(stderr, "no table data\n"); return 1; }
        FILE *f = fopen(out, "wb");
        if (!f) { perror(out); return 1; }
        fwrite(CFDataGetBytePtr(data), 1, CFDataGetLength(data), f); fclose(f);
        printf("wrote %ld bytes to %s\n", (long)CFDataGetLength(data), out);
        setProp(s, "DumpACPI", CFSTR("clear"));
    } else {
        usage();
    }
    return 0;
}
