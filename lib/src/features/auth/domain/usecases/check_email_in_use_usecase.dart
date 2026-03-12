import '../repositories/auth_repository.dart';

class CheckEmailInUseUseCase {
  const CheckEmailInUseUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call(String email) {
    return _repository.isEmailAlreadyRegistered(email);
  }
}
