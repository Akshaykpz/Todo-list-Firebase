import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({required String email, required String password});

  Future<bool> isEmailAlreadyRegistered(String email);

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
