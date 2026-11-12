# DukaanTak (Customer App)
Flutter + Firebase + Riverpod.

## Setup
1. `flutter create . --org com.dukaantak --project-name dukaantak` (generates android/ ios/ folders; keeps lib/)
2. Add `android/app/google-services.json` (Firebase console; add SHA-1/SHA-256 for Phone OTP + Google Sign-In).
3. Enable Auth providers (Phone, Google), Firestore, Storage, FCM.
4. Android: set `minSdkVersion 23` in android/app/build.gradle; add permissions ACCESS_FINE_LOCATION, INTERNET.
5. `flutter pub get && flutter build apk --release`
   Codemagic lint failure (`:firebase_core:lintVitalAnalyzeRelease`): add `lint { checkReleaseBuilds false }` inside `android { }` in android/app/build.gradle.

## Firestore schema
- users/{uid}: name, phone, addresses[{label: Home|Work|Other, line, geo}], fcmToken
- shops/{id}: name, image, verified, isOpen, location(GeoPoint), etaMin, etaMax
- products/{id}: shopId, name, unit, image, category, mrp, price
- orders/{id}: userId, shopId, items[], subtotal, deliveryFee, discount, total, payment, address, status(placed|accepted|packed|out_for_delivery|delivered), riderPhone, createdAt
- banners/{id}: image, active
- coupons/{CODE}: active, flat, minOrder

## Suggested security rules
- users/{uid}: read/write only if request.auth.uid == uid
- orders: create if request.resource.data.userId == request.auth.uid; read if resource.data.userId == request.auth.uid; customers cannot update status
- shops, products, banners, coupons: read if signed in; write false (admin/shop app only)

## Not yet included
Manual map pin-drop + saved-address manager, FCM push handling, UPI intent deep-link, Hindi localization files, rider live map.
