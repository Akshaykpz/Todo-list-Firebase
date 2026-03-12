import '../../../auth/domain/entities/app_user.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetTodosUseCase {
  const GetTodosUseCase(this._repository);

  final TodoRepository _repository;

  Future<List<Todo>> call(AppUser user) {
    return _repository.fetchTodos(
      userId: user.uid,
      idToken: user.idToken,
    );
  }
}
