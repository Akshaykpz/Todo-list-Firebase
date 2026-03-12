import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiService, this._dio, this._googleSignIn);

  static const _sessionStorageKey = 'auth_session_v1';

  final AuthApiService _apiService;
  final Dio _dio;
  final GoogleSignIn _googleSignIn;
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser?> restoreSession() async {
    if (_currentUser != null) {
      return _ensureValidSession(_currentUser!);
    }

    final prefs = await _safePreferencesInstance();
    if (prefs == null) {
      return null;
    }

    final rawSession = prefs.getString(_sessionStorageKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map<String, dynamic>) {
        await _clearPersistedSession();
        return null;
      }
      final restoredUser = _restoreUserFromStorage(decoded);
      if (restoredUser == null) {
        await _clearPersistedSession();
        _currentUser = null;
        return null;
      }
      _currentUser = restoredUser;
      return _ensureValidSession(restoredUser);
    } catch (_) {
      await _clearPersistedSession();
      _currentUser = null;
      return null;
    }
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _authenticate(email: email, password: password, isSignIn: true);
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) {
    return _authenticate(email: email, password: password, isSignIn: false);
  }

  @override
  Future<bool> isEmailAlreadyRegistered(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    try {
      final response = await _apiService.createAuthUri(<String, dynamic>{
        'identifier': normalizedEmail,
        'continueUri': 'http://localhost',
      }, Env.firebaseApiKey);

      if (response is! Map) {
        throw const AppException('Unexpected auth response from Firebase.');
      }

      final responseMap = Map<String, dynamic>.from(response);
      final registered = responseMap['registered'];
      if (registered is bool) {
        return registered;
      }

      final signInMethods = responseMap['signinMethods'];
      if (signInMethods is List) {
        return signInMethods.isNotEmpty;
      }

      final allProviders = responseMap['allProviders'];
      if (allProviders is List) {
        return allProviders.isNotEmpty;
      }

      return false;
    } on DioException catch (exception) {
      throw AppException(_firebaseAuthError(exception.response?.data));
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AppException('Google sign-in was cancelled.');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException('Google sign-in failed. Missing ID token.');
      }

      final accessToken = authentication.accessToken;
      final response = await _dio.post<dynamic>(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp',
        queryParameters: {'key': Env.firebaseApiKey},
        data: <String, dynamic>{
          'postBody': _googlePostBody(
            idToken: idToken,
            accessToken: accessToken,
          ),
          'requestUri': 'http://localhost',
          'returnSecureToken': true,
          'returnIdpCredential': true,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw const AppException('Unexpected auth response from Firebase.');
      }

      final responseMap = Map<String, dynamic>.from(data);
      final user = _mapUserFromAuthResponse(
        responseMap,
        fallbackEmail: account.email,
      );
      _currentUser = user;
      await _persistSession(user);
      return user;
    } on DioException catch (exception) {
      throw AppException(_firebaseAuthError(exception.response?.data));
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException('Google sign-in failed: $error');
    }
  }

  Future<AppUser> _authenticate({
    required String email,
    required String password,
    required bool isSignIn,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    };

    try {
      final response = isSignIn
          ? await _apiService.signIn(payload, Env.firebaseApiKey)
          : await _apiService.signUp(payload, Env.firebaseApiKey);

      if (response is! Map) {
        throw const AppException('Unexpected auth response from Firebase.');
      }
      final responseMap = Map<String, dynamic>.from(response);
      final user = _mapUserFromAuthResponse(
        responseMap,
        fallbackEmail: email.trim(),
      );
      _currentUser = user;
      await _persistSession(user);
      return user;
    } on DioException catch (exception) {
      throw AppException(_firebaseAuthError(exception.response?.data));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore provider-specific sign-out failures and clear local session.
    }
    _currentUser = null;
    await _clearPersistedSession();
  }

  Future<AppUser?> _ensureValidSession(AppUser user) async {
    if (!_isTokenExpired(user)) {
      return user;
    }

    try {
      final refreshedUser = await _refreshToken(user);
      _currentUser = refreshedUser;
      await _persistSession(refreshedUser);
      return refreshedUser;
    } catch (_) {
      await signOut();
      return null;
    }
  }

  bool _isTokenExpired(AppUser user) {
    if (user.expiresInSeconds <= 0) {
      return true;
    }

    final expiry = user.issuedAt
        .toUtc()
        .add(Duration(seconds: user.expiresInSeconds))
        .subtract(const Duration(seconds: 30));
    return DateTime.now().toUtc().isAfter(expiry);
  }

  Future<AppUser> _refreshToken(AppUser currentUser) async {
    try {
      final response = await _dio.post<dynamic>(
        'https://securetoken.googleapis.com/v1/token',
        queryParameters: {'key': Env.firebaseApiKey},
        data: <String, dynamic>{
          'grant_type': 'refresh_token',
          'refresh_token': currentUser.refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: const {'Content-Type': Headers.formUrlEncodedContentType},
        ),
      );

      final data = response.data;
      if (data is! Map) {
        throw const AppException('Unexpected refresh token response.');
      }

      final responseMap = Map<String, dynamic>.from(data);
      final refreshed = AppUser(
        uid: responseMap['user_id']?.toString() ?? currentUser.uid,
        email: currentUser.email,
        idToken: responseMap['id_token']?.toString() ?? '',
        refreshToken:
            responseMap['refresh_token']?.toString() ??
            currentUser.refreshToken,
        expiresInSeconds:
            int.tryParse(responseMap['expires_in']?.toString() ?? '') ?? 0,
        issuedAt: DateTime.now().toUtc(),
      );

      if (refreshed.idToken.isEmpty || refreshed.refreshToken.isEmpty) {
        throw const AppException('Unexpected refresh token response.');
      }

      return refreshed;
    } on DioException catch (exception) {
      throw AppException(_firebaseAuthError(exception.response?.data));
    }
  }

  Future<void> _persistSession(AppUser user) async {
    final prefs = await _safePreferencesInstance();
    if (prefs == null) {
      return;
    }
    await prefs.setString(_sessionStorageKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await _safePreferencesInstance();
    if (prefs == null) {
      return;
    }
    await prefs.remove(_sessionStorageKey);
  }

  AppUser _mapUserFromAuthResponse(
    Map<String, dynamic> responseMap, {
    required String fallbackEmail,
  }) {
    final user = AppUser(
      uid: responseMap['localId']?.toString() ?? '',
      email: responseMap['email']?.toString() ?? fallbackEmail,
      idToken: responseMap['idToken']?.toString() ?? '',
      refreshToken: responseMap['refreshToken']?.toString() ?? '',
      expiresInSeconds:
          int.tryParse(responseMap['expiresIn']?.toString() ?? '') ?? 0,
      issuedAt: DateTime.now().toUtc(),
    );

    if (user.uid.isEmpty || user.idToken.isEmpty || user.refreshToken.isEmpty) {
      throw const AppException('Unexpected auth response from Firebase.');
    }
    return user;
  }

  String _googlePostBody({required String idToken, String? accessToken}) {
    final parts = <String>[
      'id_token=${Uri.encodeQueryComponent(idToken)}',
      if (accessToken != null && accessToken.isNotEmpty)
        'access_token=${Uri.encodeQueryComponent(accessToken)}',
      'providerId=google.com',
    ];
    return parts.join('&');
  }

  AppUser? _restoreUserFromStorage(Map<String, dynamic> json) {
    final uid = json['uid']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final idToken = json['idToken']?.toString() ?? '';
    final refreshToken = json['refreshToken']?.toString() ?? '';
    final expiresInSeconds = int.tryParse(
      json['expiresInSeconds']?.toString() ?? '',
    );
    final issuedAt = DateTime.tryParse(json['issuedAt']?.toString() ?? '');

    if (uid.isEmpty ||
        email.isEmpty ||
        idToken.isEmpty ||
        refreshToken.isEmpty ||
        expiresInSeconds == null ||
        issuedAt == null) {
      return null;
    }

    return AppUser(
      uid: uid,
      email: email,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresInSeconds,
      issuedAt: issuedAt.toUtc(),
    );
  }

  Future<SharedPreferences?> _safePreferencesInstance() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _firebaseAuthError(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return 'Authentication request failed.';
    }

    final error = responseData['error'];
    if (error is! Map<String, dynamic>) {
      return 'Authentication request failed.';
    }

    final code = error['message']?.toString();
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'This email is already in use. Please log in or use a different email.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Email/password sign in is disabled in Firebase.';
      case 'CONFIGURATION_NOT_FOUND':
        final projectId = Firebase.apps.isNotEmpty
            ? Firebase.app().options.projectId
            : 'unknown-project';
        return 'Firebase Authentication is not configured for this project. '
            'Project: $projectId. Open Firebase Console > Authentication > Get started, then enable Email/Password.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Too many attempts. Try again later.';
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'INVALID_EMAIL':
      case 'INVALID_IDENTIFIER':
        return 'Enter a valid email address.';
      case 'USER_DISABLED':
        return 'This user account is disabled.';
      case 'TOKEN_EXPIRED':
      case 'INVALID_ID_TOKEN':
      case 'INVALID_REFRESH_TOKEN':
        return 'Session expired. Please sign in again.';
      default:
        return code ?? 'Authentication request failed.';
    }
  }
}
