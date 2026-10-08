#!/bin/bash
# Tries the panel's 240 Hz mode and reverts to the current mode after 15 s unless you click "Keep".
# Run (no sudo):  bash /Volumes/1401/refresh240/test-240hz.sh          list modes only:  ... test-240hz.sh list
# The switch is made "for this script only", so if the screen goes black the mode reverts when the
# dialog times out (or when the script dies); nothing is saved unless you click Keep.
osascript -l JavaScript - "$@" <<'JS'
ObjC.import('ApplicationServices');
function run(argv) {
  var listOnly = argv.length > 0 && argv[0] === 'list';
  var d = $.CGMainDisplayID();
  var modes = ObjC.castRefToObject($.CGDisplayCopyAllDisplayModes(d, $()));
  var out = [], target = null, best = 0;
  for (var i = 0; i < modes.count; i++) {
    var m = modes.objectAtIndex(i);
    var w = $.CGDisplayModeGetWidth(m), h = $.CGDisplayModeGetHeight(m);
    var pw = $.CGDisplayModeGetPixelWidth(m), r = $.CGDisplayModeGetRefreshRate(m);
    out.push(w + 'x' + h + ' (pixels ' + pw + ') @ ' + r + ' Hz');
    if (w == 2560 && h == 1600 && pw == 2560 && r > 61 && r > best) { best = r; target = m; }
  }
  var cur = $.CGDisplayCopyDisplayMode(d);
  var head = 'current: ' + $.CGDisplayModeGetWidth(cur) + 'x' + $.CGDisplayModeGetHeight(cur) + ' @ ' + $.CGDisplayModeGetRefreshRate(cur) + ' Hz\nmodes:\n  ' + out.join('\n  ');
  if (listOnly) return head;
  if (!target) return head + '\n\nNo 2560x1600 mode above 60 Hz is offered (override not active, or the driver refused the timing).';

  var cfg = Ref(); $.CGBeginDisplayConfiguration(cfg);
  $.CGConfigureDisplayWithDisplayMode(cfg[0], d, target, $());
  var err = $.CGCompleteDisplayConfiguration(cfg[0], 0);          // kCGConfigureForAppOnly
  if (err != 0) return head + '\n\nSwitch to ' + best + ' Hz failed, CGError ' + err;

  var app = Application.currentApplication(); app.includeStandardAdditions = true;
  var keep = false;
  try {
    var res = app.displayDialog('Now at ' + best + ' Hz. Keep it?\n\nGoing back in 15 s unless you click Keep.',
      { buttons: ['Revert', 'Keep'], defaultButton: 'Revert', givingUpAfter: 15 });
    keep = !res.gaveUp && res.buttonReturned === 'Keep';
  } catch (e) { keep = false; }

  var c2 = Ref(); $.CGBeginDisplayConfiguration(c2);
  $.CGConfigureDisplayWithDisplayMode(c2[0], d, keep ? target : cur, $());
  var e2 = $.CGCompleteDisplayConfiguration(c2[0], keep ? 2 : 0);   // 2 = kCGConfigurePermanently
  return head + '\n\n' + (keep ? 'Kept ' + best + ' Hz (saved, CGError ' + e2 + ').' : 'Reverted to ' + $.CGDisplayModeGetRefreshRate(cur) + ' Hz.');
}
JS
[ "${1:-}" = list ] && exit 0
echo; echo "== driver log (last 2 min)"
/usr/bin/log show --last 2m --style compact --predicate 'process == "kernel"' 2>/dev/null \
  | grep -E "switchMode|validateDetailedTiming|refused|setDetailedTimings|applyModeSet|flipResult|DP-4|NVKMS (ERROR|WARN)" \
  | grep -v "pclk 293760000 -> OK" | tail -40
