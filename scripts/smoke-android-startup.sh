#!/usr/bin/env bash
set -euo pipefail

apk=${1:?Uso: smoke-android-startup.sh APK}
package=com.example.diabeta
export ANDROID_SERIAL=emulator-5554
export PATH="${ANDROID_HOME:?Falta ANDROID_HOME}/platform-tools:$PATH"
emulator_log=$(mktemp)
ui_xml=/sdcard/diabeta-smoke.xml

"${ANDROID_HOME:?Falta ANDROID_HOME}/emulator/emulator" -avd diabeta-smoke -port 5554 \
  -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect >"$emulator_log" 2>&1 &
emulator_pid=$!
cleanup() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    tail -n 50 "$emulator_log"
    timeout 10 adb logcat -d -b crash -t 100 || true
  fi
  kill "$emulator_pid" 2>/dev/null || true
  rm -f "$emulator_log"
}
trap cleanup EXIT

timeout 120 adb wait-for-device
for attempt in {1..45}; do
  booted=$(timeout 5 adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
  [[ $booted == 1 ]] && break
  sleep 2
done
[[ $booted == 1 ]] || { echo 'El emulador no terminó de arrancar.'; exit 1; }

adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb install "$apk"
launch=$(adb shell am start -W -n "$package/.MainActivity")
printf '%s\n' "$launch"
grep -q '^Status: ok' <<<"$launch"

for attempt in {1..8}; do
  if timeout 12 adb shell uiautomator dump "$ui_xml" >/dev/null 2>&1; then
    layout=$(adb shell cat "$ui_xml")
    if grep -Eq "package=\"$package\"" <<<"$layout" &&
      grep -Eq '(text|content-desc)="Entrar"' <<<"$layout"; then
      adb shell pidof "$package" >/dev/null
      echo 'Diabeta arrancó y mostró la pantalla de acceso.'
      exit 0
    fi
  fi
  sleep 2
done
echo 'Diabeta no mostró la pantalla de acceso.'
exit 1
