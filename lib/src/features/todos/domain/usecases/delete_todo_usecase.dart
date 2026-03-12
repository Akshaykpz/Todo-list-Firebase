import '../../../auth/domain/entities/app_user.dart';
import '../repositories/todo_repository.dart';

class DeleteTodoUseCase {
  const DeleteTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<void> call(AppUser user, String todoId) {
    return _repository.deleteTodo(
      userId: user.uid,
      idToken: user.idToken,
      todoId: todoId,
    );
  }
}
