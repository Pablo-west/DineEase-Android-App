# DineEase

DineEase is a Flutter food-ordering app with customer and admin/chef flows.

Customers can browse meals, place orders, track progress, and view order notices.  
Admins/chefs can manage orders, foods, and categories.

## Features

- Email/password authentication
- Customer cart + checkout flow
- Delivery destination support (doorstep/table)
- Real-time order stage updates
- Admin/chef order management:
  - stage updates
  - search
  - stage filtering
  - date range filtering
  - filtered-orders view page
- Admin/chef food management:
  - add/edit/delete foods
  - category create/rename/delete
  - foods summary panel
- Dynamic categories (from Firestore, not hardcoded)
- Notification center:
  - notice list page
  - grouped by order number and food names
  - unread badge count on Home
- Popular and Delicious “View All” pages

## Tech Stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Cached Network Image
- Firebase Messaging (client integration)

## Project Structure

- `lib/features/` UI features (auth, home, cart, orders, profile, admin)
- `lib/core/` shared state, services, widgets, themes
- `functions/` Firebase Cloud Functions (order stage notification trigger)
- `assets/` images and icons

## Firebase Setup

### 1) Create Firebase project

1. Create project in Firebase Console
2. Enable Auth (Email/Password)
3. Create Firestore database

### 2) Add config files

Android:
- Download `google-services.json`
- Place in `android/app/google-services.json`

iOS (optional):
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/GoogleService-Info.plist`

### 3) Firestore Rules

Use:

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
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'chef']
        );
    }

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /fcmTokens/{tokenId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    match /foods/{foodId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'chef'];
    }

    match /food_categories/{categoryId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'chef'];
    }

    match /notices/{noticeId} {
      allow read, update: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'chef'];
    }
  }
}
```

### 4) Admin/Chef role

Set role in Firestore:

```txt
users/{uid} {
  role: "admin" // or "chef"
}
```

## Notifications

### In-app notices (works on Spark plan)

- When admin changes order stage, app writes a notice document
- User sees notices on notifications page
- Home icon shows unread count

### Phone push notifications (requires server trigger)

This repo includes `functions/index.js` trigger `onOrderStageChanged`.  
To send push notifications while app is closed, deploy Cloud Functions.

Important:
- Cloud Functions deployment requires Firebase Blaze plan.
- If not on Blaze, in-app notice list + unread badge still work.

## Cloud Functions Deploy

From project root:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Web Build

```bash
flutter build web
```

## Android Release Build

```bash
flutter build apk --release
```

