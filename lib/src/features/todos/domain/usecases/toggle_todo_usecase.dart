import '../../../auth/domain/entities/app_user.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class ToggleTodoUseCase {
  const ToggleTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(AppUser user, Todo todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repository.updateTodo(
      userId: user.uid,
      idToken: user.idToken,
      todo: updatedTodo,
    );
    return updatedTodo;
  }
}
