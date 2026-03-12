import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/auth_api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/check_email_in_use_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio);
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  return GoogleSignIn(
    scopes: const ['email'],
    clientId: webClientId.isEmpty ? null : webClientId,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final dio = ref.watch(dioProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRepositoryImpl(apiService, dio, googleSignIn);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

final checkEmailInUseUseCaseProvider = Provider<CheckEmailInUseUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CheckEmailInUseUseCase(repository);
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    return repository.restoreSession();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    final useCase = ref.read(signInUseCaseProvider);
    state = await AsyncValue.guard(
      () => useCase(email: email, password: password),
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    final useCase = ref.read(signUpUseCaseProvider);
    state = await AsyncValue.guard(
      () => useCase(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    final useCase = ref.read(signInWithGoogleUseCaseProvider);
    state = await AsyncValue.guard(useCase.call);
  }

  Future<void> signOut() async {
    await _signOutAndClearState();
  }

  Future<void> invalidateSession() async {
    await _signOutAndClearState();
  }

  Future<void> _signOutAndClearState() async {
    try {
      final useCase = ref.read(signOutUseCaseProvider);
      await useCase();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(
        error is AppException ? error : AppException(error.toString()),
        stackTrace,
      );
    }
  }
}
