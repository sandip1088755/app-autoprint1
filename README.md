# AutoPrint Pay (Android)

Shop owner ke phone par chalta hai. Payment notification / SMS padhta hai aur AutoPrint webhook par bhejta hai.

## APK banana (GitHub se, phone se bhi ho jata hai)
1. github.com par naya repo banao (Private bhi chalega).
2. Is folder ki saari files upload karo (`.github/workflows/build.yml` samet).
3. Repo ke **Actions** tab me "Build APK" chalega (ya "Run workflow" dabao).
4. Khatam hone par run kholo, neeche **Artifacts → AutoPrintPay-apk** download karo (zip me app-debug.apk).
5. APK ko apni site par `/assets/AutoPrintPay.apk` naam se upload karo.

## Shop owner ke liye
1. APK install karo (Unknown sources allow).
2. Shop panel → Settings → Auto-Verify → "📲 App me 1-tap setup" dabao, ya URL + key khud daalo.
3. App me: Notification access do, battery restriction hatao.
4. "Test bhejo" dabao.
