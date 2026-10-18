# Server changes (htdocs repo)

## 1. api/upload.php
Final json_out mein ye key add karein:

    'upi_id' => $shop['upi_id'] ?? '',

Aur shop query mein `upi_id` select hona chahiye:

    SELECT id, shop_name, upi_id, is_suspended, approval_status ...

## 2. Shop QR -> shop_id
QR mein abhi slug hai (`/s/?slug=...`), upload ko numeric shop_id chahiye.
Ek chhota endpoint `api/shop-by-slug.php` banana hoga jo `{id, shop_name}` return kare.
