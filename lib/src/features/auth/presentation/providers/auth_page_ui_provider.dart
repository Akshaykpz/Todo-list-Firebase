import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import 'auth_providers.dart';

@immutable
class AuthPageUiState {
  const AuthPageUiState({
    this.isSignInMode = true,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final bool isSignInMode;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  AuthPageUiState copyWith({
    bool? isSignInMode,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return AuthPageUiState(
      isSignInMode: isSignInMode ?? this.isSignInMode,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

final authPageUiControllerProvider =
    NotifierProvider<AuthPageUiController, AuthPageUiState>(
      AuthPageUiController.new,
    );

class AuthPageUiController extends Notifier<AuthPageUiState> {
  @override
  AuthPageUiState build() => const AuthPageUiState();

  void toggleMode() {
    state = state.copyWith(isSignInMode: !state.isSignInMode);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      obscureConfirmPassword: !state.obscureConfirmPassword,
    );
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least 1 number.';
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      return 'Password must contain at least 1 special character.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirm != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> continueWithGoogle() {
    return ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  Future<void> submit({required String email, required String password}) async {
    final controller = ref.read(authControllerProvider.notifier);
    if (state.isSignInMode) {
      await controller.signIn(email: email, password: password);
      return;
    }
    final checkEmailInUse = ref.read(checkEmailInUseUseCaseProvider);
    final isEmailInUse = await checkEmailInUse(email.trim());
    if (isEmailInUse) {
      throw const AppException(
        'This email is already in use. Please log in or use a different email.',
      );
    }
    await controller.signUp(email: email, password: password);
  }
}
