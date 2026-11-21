#!/usr/bin/env bash
# Comprobaciones de seguridad de un APK release: no depurable y sin tráfico HTTP
# sin cifrar.
# Uso: scripts/check-release-apk.sh ruta/app-release.apk
set -euo pipefail
APK="${1:?Uso: $0 ruta/app-release.apk}"
AAPT2=$(ls "${ANDROID_HOME:?Define ANDROID_HOME}"/build-tools/*/aapt2 | sort -V | tail -1)
"$AAPT2" dump badging "$APK" > /tmp/badging.txt
"$AAPT2" dump xmltree --file AndroidManifest.xml "$APK" > /tmp/manifest.txt
grep -E "^package:" /tmp/badging.txt
if grep -q "application-debuggable" /tmp/badging.txt; then echo "ERROR: el APK es depurable"; exit 1; fi
if grep -qi "usesCleartextTraffic.*0xffffffff" /tmp/manifest.txt; then echo "ERROR: el APK permite HTTP sin cifrar"; exit 1; fi
echo "OK: no depurable y sin tráfico HTTP sin cifrar."
