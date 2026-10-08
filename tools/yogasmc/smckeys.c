// smckeys: list or read AppleSMC keys (read-only). Usage: smckeys [prefix|KEY...]
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
typedef struct { uint32_t dataSize; uint32_t dataType; uint8_t dataAttributes; } KeyInfo;
typedef struct { char major, minor, build, reserved[1]; uint16_t release; } Vers;
typedef struct { uint16_t version, length; uint32_t cpuPLimit, gpuPLimit, memPLimit; } PLimit;
typedef struct { uint32_t key; Vers vers; PLimit pLimitData; KeyInfo keyInfo; uint8_t result, status, data8; uint32_t data32; uint8_t bytes[32]; } SMCParam;
static io_connect_t conn;
static uint32_t k2u(const char *s) { return (uint32_t)s[0]<<24 | (uint32_t)s[1]<<16 | (uint32_t)s[2]<<8 | (uint32_t)s[3]; }
static void u2k(uint32_t u, char *s) { s[0]=u>>24; s[1]=u>>16; s[2]=u>>8; s[3]=u; s[4]=0; }
static kern_return_t call(SMCParam *in, SMCParam *out) { size_t o = sizeof(*out); return IOConnectCallStructMethod(conn, 2, in, sizeof(*in), out, &o); }
static int readKey(uint32_t key, KeyInfo *ki, uint8_t *bytes) {
    SMCParam in = {0}, out = {0}; in.key = key; in.data8 = 9;
    if (call(&in, &out) || out.result) return -1; *ki = out.keyInfo;
    memset(&in, 0, sizeof in); in.key = key; in.keyInfo.dataSize = ki->dataSize; in.data8 = 5;
    if (call(&in, &out) || out.result) return -2; memcpy(bytes, out.bytes, 32); return 0;
}
static void show(uint32_t key) {
    KeyInfo ki; uint8_t b[32]; char k[5], t[5]; u2k(key, k);
    int r = readKey(key, &ki, b); u2k(ki.dataType, t);
    if (r) { printf("%s  (read error %d)\n", k, r); return; }
    printf("%s  [%s] %2u  ", k, t, ki.dataSize);
    for (uint32_t i = 0; i < ki.dataSize && i < 32; i++) printf("%02x", b[i]);
    if (!strcmp(t, "sp78") && ki.dataSize == 2) printf("  = %.2f", (int16_t)(b[0]<<8|b[1]) / 256.0);
    else if (!strcmp(t, "fpe2") && ki.dataSize == 2) printf("  = %.2f", (uint16_t)(b[0]<<8|b[1]) / 4.0);
    else if (!strcmp(t, "flt ") && ki.dataSize == 4) { float f; memcpy(&f, b, 4); printf("  = %.2f", f); }
    else if (!strcmp(t, "ui8 ")) printf("  = %u", b[0]);
    else if (!strcmp(t, "ui16")) printf("  = %u", b[0]<<8|b[1]);
    else if (!strcmp(t, "ui32")) printf("  = %u", (uint32_t)b[0]<<24|b[1]<<16|b[2]<<8|b[3]);
    printf("\n");
}
int main(int argc, char **argv) {
    io_service_t s = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!s || IOServiceOpen(s, mach_task_self(), 0, &conn)) { fprintf(stderr, "cannot open AppleSMC\n"); return 1; }
    if (argc > 1 && strlen(argv[1]) == 4 && argc >= 2 && argv[1][0] != '-') {
        for (int i = 1; i < argc; i++) show(k2u(argv[i])); return 0;
    }
    const char *prefix = argc > 1 ? argv[1] + (argv[1][0] == '-') : "";
    KeyInfo ki; uint8_t b[32];
    if (readKey(k2u("#KEY"), &ki, b)) { fprintf(stderr, "#KEY failed\n"); return 1; }
    uint32_t n = (uint32_t)b[0]<<24|b[1]<<16|b[2]<<8|b[3];
    for (uint32_t i = 0; i < n; i++) {
        SMCParam in = {0}, out = {0}; in.data8 = 8; in.data32 = i;
        if (call(&in, &out) || out.result) continue;
        char k[5]; u2k(out.key, k);
        if (!strncmp(k, prefix, strlen(prefix))) show(out.key);
    }
    return 0;
}
