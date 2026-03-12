import '../../../auth/domain/entities/app_user.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class UpdateTodoUseCase {
  const UpdateTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<void> call(AppUser user, Todo todo) {
    return _repository.updateTodo(
      userId: user.uid,
      idToken: user.idToken,
      todo: todo,
    );
  }
}
