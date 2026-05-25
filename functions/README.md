# Firebase Functions for Push Notifications

This folder contains the Firebase Cloud Functions that send phone push notifications for:

- new absences recorded by teachers
- exclusion decisions approved/rejected by the department
- justification decisions accepted/rejected by the admin

## How it works

1. The Flutter app writes Firestore documents to `absences` and `notifications`.
2. These Cloud Functions listen for new documents.
3. The function looks up the student's FCM token(s).
4. Firebase Cloud Messaging sends the push notification to the phone, even if the app is closed.

## Local setup

Install dependencies:

```bash
npm install
```

Run emulators:

```bash
npm run serve
```

Deploy:

```bash
npm run deploy
```
