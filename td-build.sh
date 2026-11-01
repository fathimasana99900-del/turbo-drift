#!/bin/bash
# Turbo Drift: builds a test APK (test ads) and a signed release APK (live ads)
set -e
ADMOB_APP_ID="ca-app-pub-5059428712375364~8338105610"
mkdir -p www assets
for f in turbo-drift*.html; do
  if grep -q "AD_TEST" "$f"; then cp "$f" www/index.html; break; fi
done
[ -f www/index.html ] || { echo "ERROR: no game file with the ad code (use the new turbo-drift.html)"; exit 1; }
cp "$(ls td-icon-only*.png | head -1)" assets/icon-only.png
cp "$(ls td-icon-foreground*.png | head -1)" assets/icon-foreground.png
cp "$(ls td-icon-background*.png | head -1)" assets/icon-background.png
echo '{"name":"turbo-drift","version":"1.0.0","private":true,"dependencies":{"@capacitor/core":"^7.0.0","@capacitor/android":"^7.0.0","@capacitor-community/admob":"^7.0.0"},"devDependencies":{"@capacitor/cli":"^7.0.0"}}' > package.json
echo '{"appId":"com.artrading.turbodrift","appName":"Turbo Drift","webDir":"www"}' > capacitor.config.json
npm install
npx cap add android
npx @capacitor/assets generate --android
sed -i "s#</application>#<meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"$ADMOB_APP_ID\"/></application>#" android/app/src/main/AndroidManifest.xml
npx cap sync android
(cd android && chmod +x gradlew && ./gradlew assembleDebug)
cp android/app/build/outputs/apk/debug/app-debug.apk TurboDrift-test.apk
sed -i 's/AD_TEST=true/AD_TEST=false/' www/index.html
npx cap copy android
(cd android && ./gradlew assembleRelease)
echo "$KS_B64" | base64 -d > td.jks
BT=$(ls -d $ANDROID_HOME/build-tools/* | sort -V | tail -1)
$BT/zipalign -p 4 android/app/build/outputs/apk/release/app-release-unsigned.apk aligned.apk
$BT/apksigner sign --ks td.jks --ks-pass pass:"$KS_PASS" --key-pass pass:"$KS_PASS" --ks-key-alias stacktower --out TurboDrift-release.apk aligned.apk
