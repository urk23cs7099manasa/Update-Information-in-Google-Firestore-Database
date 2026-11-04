# Update Information in Google Firestore Database

A Flutter app for loading and updating existing student records in a Cloud
Firestore `students` collection.

## Features

- Loads a student record by registration number.
- Trims and uppercases the registration number to match the document IDs used
  by the student records app.
- Allows editing the student's name, department, and whole-number marks
  between 0 and 100.
- Updates an existing document without replacing its other fields, and adds
  an `updatedAt` server timestamp.
- Reports missing records, invalid input, Firebase setup issues, and Firestore
  errors in the app.
- Includes widget tests using an in-memory Firestore fake.

## Requirements

- Flutter SDK and Dart SDK `^3.13.7`.
- A Firebase project with Cloud Firestore enabled.
- A registered Firebase Web app for Chrome, or Android app for Android.
- Firestore security rules that authorize reads and updates to `students`.

The app does not implement authentication. Do not allow unrestricted public
access to student records; configure authentication and suitable Firestore
rules before using real student data.

## Configure Firebase

1. Create a Firebase project and enable Cloud Firestore.
2. Register a Web app and/or Android app in Firebase project settings.
3. Copy the configuration template:

   ```powershell
   Copy-Item firebase_config.example.json firebase_config.json
   ```

4. Fill `firebase_config.json` with the values from Firebase app settings:
   - `FIREBASE_API_KEY`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_WEB_APP_ID` for web
   - `FIREBASE_ANDROID_APP_ID` for Android
   - `FIREBASE_AUTH_DOMAIN` and `FIREBASE_STORAGE_BUCKET` when provided

The local `firebase_config.json` is ignored by Git. Firebase client settings
are not a substitute for Firestore security rules. Never include service
account credentials or other server secrets in a Flutter app.

## Student data

Loadable records must already exist in the `students` collection, with the
uppercase registration number as the document ID. The app expects:

| Field | Type |
| --- | --- |
| `name` | String |
| `registrationNumber` | String |
| `department` | String |
| `marks` | Number |

On update, only `name`, `department`, `marks`, and `updatedAt` are written;
existing fields such as `registrationNumber` and `createdAt` are preserved.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=firebase_config.json
```

For Android:

```bash
flutter run -d <device-id> --dart-define-from-file=firebase_config.json
```

If Firebase is not configured for the selected platform, the app displays
setup guidance instead of starting an unconfigured connection.

## Test and analyze

```bash
flutter test
flutter analyze
```

Widget tests use `fake_cloud_firestore`; they do not require a live Firebase
project or network connection.

## Build

```bash
flutter build web --dart-define-from-file=firebase_config.json
flutter build apk --dart-define-from-file=firebase_config.json
```

See the [Flutter deployment guide](https://docs.flutter.dev/deployment) for
platform-specific setup.
