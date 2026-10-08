#!/bin/bash
# Lists display modes, or tries one HiDPI mode safely:
#   bash /Volumes/1401/hidpi/test-hidpi.sh list
#   bash /Volumes/1401/hidpi/test-hidpi.sh 1280      (HiDPI "looks like 1280x800"; also 1440, 1600, 1680)
# The switch is made for this script only: it goes back after 15 s unless you click Keep, and nothing is
# saved unless you click Keep. If the whole Mac freezes, hold power - after restart you are back at 2560x1600.
osascript -l JavaScript - "$@" <<'JS'
ObjC.import('ApplicationServices');
function run(argv) {
  var want = argv.length ? argv[0] : 'list';
  var d = $.CGMainDisplayID();
  var modes = ObjC.castRefToObject($.CGDisplayCopyAllDisplayModes(d, $()));
  var out = [], target = null;
  for (var i = 0; i < modes.count; i++) {
    var m = modes.objectAtIndex(i);
    var w = $.CGDisplayModeGetWidth(m), h = $.CGDisplayModeGetHeight(m), pw = $.CGDisplayModeGetPixelWidth(m), ph = $.CGDisplayModeGetPixelHeight(m);
    out.push('looks like ' + w + 'x' + h + '  pixels ' + pw + 'x' + ph + (pw > w ? '  (HiDPI)' : '') + ' @ ' + $.CGDisplayModeGetRefreshRate(m) + ' Hz');
    if (want != 'list' && w == Number(want) && pw == 2 * w) target = m;
  }
  var cur = $.CGDisplayCopyDisplayMode(d);
  var head = 'current: looks like ' + $.CGDisplayModeGetWidth(cur) + 'x' + $.CGDisplayModeGetHeight(cur) + ', pixels ' + $.CGDisplayModeGetPixelWidth(cur) + '\nmodes:\n  ' + out.join('\n  ');
  if (want == 'list') return head;
  if (!target) return head + '\n\nNo HiDPI mode "looks like ' + want + '" is offered (override not installed, or the driver refused it).';
  var cfg = Ref(); $.CGBeginDisplayConfiguration(cfg);
  $.CGConfigureDisplayWithDisplayMode(cfg[0], d, target, $());
  var err = $.CGCompleteDisplayConfiguration(cfg[0], 0);              // for this script only
  if (err != 0) return 'switch failed, CGError ' + err;
  var app = Application.currentApplication(); app.includeStandardAdditions = true; var keep = false;
  try { var r = app.displayDialog('Now "looks like ' + want + '" (HiDPI). Keep it?\n\nGoing back in 15 s unless you click Keep.',
        { buttons: ['Revert', 'Keep'], defaultButton: 'Revert', givingUpAfter: 15 });
        keep = !r.gaveUp && r.buttonReturned === 'Keep'; } catch (e) {}
  var c2 = Ref(); $.CGBeginDisplayConfiguration(c2);
  $.CGConfigureDisplayWithDisplayMode(c2[0], d, keep ? target : cur, $());
  var e2 = $.CGCompleteDisplayConfiguration(c2[0], keep ? 2 : 0);     // 2 = save permanently
  return keep ? 'Kept "looks like ' + want + '" (saved, CGError ' + e2 + ').' : 'Reverted.';
}
JS
[ "${1:-list}" = list ] && exit 0
echo "== display driver log (last 1 min)"
/usr/bin/log show --last 1m --style compact --predicate 'process == "kernel"' 2>/dev/null | grep -E "switchMode|REFUSED|createSurface|applyModeSet|Xid" | tail -10
