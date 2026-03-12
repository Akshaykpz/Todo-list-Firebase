# Todo Firebase App (Hiring Task)

Flutter app built with:
- Riverpod
- Retrofit
- Dio
- Freezed
- Json Serializable
- Firebase Auth (REST)
- Firebase Realtime Database (REST)
- Clean Architecture

## Project Structure

```text
lib/
  src/
    core/
      config/
      error/
      network/
    features/
      auth/
        data/
        domain/
        presentation/
      todos/
        data/
        domain/
        presentation/
```

## Firebase Setup

1. Create a Firebase project.
2. Enable `Authentication -> Sign-in method -> Email/Password`.
3. Create `Realtime Database`.
4. Use database URL format:
   `https://<db-name>.<region>.firebasedatabase.app/`

Recommended database rules for this task:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=FIREBASE_API_KEY=YOUR_WEB_API_KEY --dart-define=FIREBASE_DATABASE_URL=https://YOUR_DB_NAME.YOUR_REGION.firebasedatabase.app/ --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID --dart-define=FIREBASE_APP_ID_ANDROID=YOUR_ANDROID_APP_ID
```

Use the app-id flag for your target:
- Android: `FIREBASE_APP_ID_ANDROID`
- iOS: `FIREBASE_APP_ID_IOS`
- Web: `FIREBASE_APP_ID_WEB`
- Windows: `FIREBASE_APP_ID_WINDOWS`
- macOS: `FIREBASE_APP_ID_MACOS`

## Notes

- Auth session is in-memory for this task.
- Todos are stored per user in:
  `users/{uid}/todos/{todoId}`.
- API communication is done via Firebase REST endpoints with Dio + Retrofit.
- Since `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` is used, you must provide all required `--dart-define` values for your target platform.
