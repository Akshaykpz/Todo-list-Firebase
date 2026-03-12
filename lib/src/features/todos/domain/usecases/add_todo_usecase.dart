import '../../../auth/domain/entities/app_user.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class AddTodoUseCase {
  const AddTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(AppUser user, String title) {
    return _repository.addTodo(
      userId: user.uid,
      idToken: user.idToken,
      title: title,
    );
  }
}
