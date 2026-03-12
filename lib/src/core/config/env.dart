import 'package:firebase_core/firebase_core.dart';

class Env {
  const Env._();
  static const String _projectDefaultDatabaseUrl =
      'https://my-todo-mission-app-default-rtdb.firebaseio.com/';

  static String get firebaseApiKey {
    const primary = String.fromEnvironment('FIREBASE_API_KEY');
    if (primary.isNotEmpty) {
      return primary;
    }

    // Backward-compatible fallback for earlier naming.
    const legacy = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    if (legacy.isNotEmpty) {
      return legacy;
    }

    if (Firebase.apps.isNotEmpty) {
      final apiKey = Firebase.app().options.apiKey;
      if (apiKey.isNotEmpty) {
        return apiKey;
      }
    }

    throw const FormatException(
      'Missing FIREBASE_API_KEY. '
      'Run with --dart-define=FIREBASE_API_KEY=...',
    );
  }

  static String get firebaseDatabaseUrl {
    final resolved = firebaseDatabaseUrlOrNull;
    if (resolved != null) {
      return resolved;
    }

    throw const FormatException(
      'Missing FIREBASE_DATABASE_URL. '
      'Run with --dart-define=FIREBASE_DATABASE_URL=https://<db-name>.<region>.firebasedatabase.app/',
    );
  }

  static String? get firebaseDatabaseUrlOrNull {
    const value = String.fromEnvironment('FIREBASE_DATABASE_URL');
    if (value.isNotEmpty) {
      return _normalizedUrl(value);
    }

    if (Firebase.apps.isNotEmpty) {
      final options = Firebase.app().options;
      final fromOptions = options.databaseURL ?? '';
      if (fromOptions.isNotEmpty) {
        return _normalizedUrl(fromOptions);
      }
    }

    return _normalizedUrl(_projectDefaultDatabaseUrl);
  }

  static String _normalizedUrl(String value) =>
      value.endsWith('/') ? value : '$value/';
}
