# AutoPrint Customer App

Android app jisse customer shop ka QR scan karke file upload kare, pages/copies chune, UPI se pay kare.

## Build (GitHub Actions)
Push karne par `.github/workflows/build.yml` APK banata hai. Actions tab se `autoprint-customer-apk` download karein.

## Server dependency
- `/api/calculate-price.php`
- `/api/upload.php` (response mein `upi_id` chahiye, see SERVER_CHANGES.md)
- `/api/submit-utr.php`
