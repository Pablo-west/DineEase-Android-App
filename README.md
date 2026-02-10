# DineEase

DineEase is a Flutter app for food ordering with customer and admin/chef flows.  
Customers browse meals, place orders, and track order stages.  
Admins/chefs manage foods and update order stages in real time.

## Features

- Email/password authentication
- Customer ordering flow with delivery destination and payment mode
- Real-time order tracking (placed → preparing → in kitchen → delivered)
- Admin/chef dashboard (Orders + Foods management)
- Firebase Firestore as backend
- Image caching for food photos

## Tech Stack

- Flutter (Android/iOS/Web)
- Firebase Auth
- Cloud Firestore
- Cached Network Image

## Project Structure

- `lib/features/` UI flows for auth, home, cart, orders, profile, admin
- `lib/core/` shared models, widgets, and app state
- `assets/` images and icons

## Firebase Setup (Required)

This repo does **not** include Firebase config files.  
You must add them locally after cloning.

### 1) Create Firebase Project

1. Go to Firebase Console.
2. Create a new project.
3. Enable **Authentication → Email/Password**.
4. Create Firestore database.

### 2) Add Android Firebase Config

1. In Firebase Console → Project Settings → **Your Apps** → Add Android app.
2. Package name must match `applicationId` in `android/app/build.gradle`.
3. Download `google-services.json`.
4. Place it in:

```
android/app/google-services.json
```

### 3) Add iOS Firebase Config (Optional)

1. Add iOS app in Firebase Console.
2. Download `GoogleService-Info.plist`.
3. Place it in:

```
ios/Runner/GoogleService-Info.plist
```

### 4) Firebase Firestore Rules

Use the following rules (adjust if needed):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /orders/{orderId} {
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;

      allow read, update, delete: if request.auth != null
        && (
          resource.data.userId == request.auth.uid ||
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role
            in ['admin','chef']
        );
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /foods/{foodId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role
          in ['admin','chef'];
    }
  }
}
```

## Admin / Chef Access

To enable admin access, create a user document in Firestore:

```
users/{uid} {
  role: "admin"
}
```

Admins can:
- View all orders
- Search + filter orders
- Update order stage
- Add/edit food items

## Run Locally

1. Install Flutter and dependencies.
2. Run:

```
flutter pub get
flutter run
```

## Web Build (Optional)

```
flutter build web
```

## Release Build (Android)

```
flutter build apk --release
```

## Notes

- `google-services.json` and `GoogleService-Info.plist` are not committed.
- Do not commit `node_modules/` or build folders.

---

Built for DineEase.
