import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> fetchTodos({
    required String userId,
    required String idToken,
  });

  Future<Todo> addTodo({
    required String userId,
    required String idToken,
    required String title,
  });

  Future<void> updateTodo({
    required String userId,
    required String idToken,
    required Todo todo,
  });

  Future<void> deleteTodo({
    required String userId,
    required String idToken,
    required String todoId,
  });
}
