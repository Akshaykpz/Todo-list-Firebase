import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_api_service.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._apiService);

  final TodoApiService _apiService;

  @override
  Future<List<Todo>> fetchTodos({
    required String userId,
    required String idToken,
  }) async {
    try {
      final response = await _apiService.fetchTodos(userId, idToken);
      if (response == null) {
        return const [];
      }
      if (response is! Map) {
        throw const AppException('Unexpected todos response from Firebase.');
      }
      final responseMap = Map<String, dynamic>.from(response);

      final todos = <Todo>[];
      responseMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          todos.add(_mapTodoFromFirebase(key, value));
        } else if (value is Map) {
          todos.add(
            _mapTodoFromFirebase(key, Map<String, dynamic>.from(value)),
          );
        }
      });

      todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return todos;
    } on DioException catch (exception) {
      throw AppException(_firebaseDatabaseError(exception));
    }
  }

  @override
  Future<Todo> addTodo({
    required String userId,
    required String idToken,
    required String title,
  }) async {
    final now = DateTime.now().toUtc();
    final normalizedTitle = title.trim();

    try {
      final response = await _apiService.createTodo(userId, <String, dynamic>{
        'title': normalizedTitle,
        'isCompleted': false,
        'createdAt': now.toIso8601String(),
      }, idToken);

      if (response is! Map) {
        throw const AppException('Unexpected create todo response.');
      }
      final responseMap = Map<String, dynamic>.from(response);

      final todoId = responseMap['name']?.toString() ?? '';
      if (todoId.isEmpty) {
        throw const AppException('Firebase did not return a todo id.');
      }

      return Todo(
        id: todoId,
        title: normalizedTitle,
        isCompleted: false,
        createdAt: now,
      );
    } on DioException catch (exception) {
      throw AppException(_firebaseDatabaseError(exception));
    }
  }

  @override
  Future<void> updateTodo({
    required String userId,
    required String idToken,
    required Todo todo,
  }) async {
    try {
      await _apiService.updateTodo(userId, todo.id, <String, dynamic>{
        'title': todo.title,
        'isCompleted': todo.isCompleted,
        'createdAt': todo.createdAt.toUtc().toIso8601String(),
      }, idToken);
    } on DioException catch (exception) {
      throw AppException(_firebaseDatabaseError(exception));
    }
  }

  @override
  Future<void> deleteTodo({
    required String userId,
    required String idToken,
    required String todoId,
  }) async {
    try {
      await _apiService.deleteTodo(userId, todoId, idToken);
    } on DioException catch (exception) {
      throw AppException(_firebaseDatabaseError(exception));
    }
  }

  Todo _mapTodoFromFirebase(String id, Map<String, dynamic> raw) {
    return Todo(
      id: id,
      title: raw['title']?.toString() ?? '',
      isCompleted: raw['isCompleted'] == true,
      createdAt:
          DateTime.tryParse(raw['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  String _firebaseDatabaseError(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      final remoteError = _extractRemoteError(exception.response?.data);
      final normalized = remoteError.toLowerCase();

      if (normalized.contains('permission denied')) {
        return 'Permission denied by Firebase Realtime Database rules.';
      }
      if (normalized.contains('auth token is expired') ||
          normalized.contains('token expired') ||
          normalized.contains('invalid id token') ||
          normalized.contains('id token is expired') ||
          normalized.contains('invalid refresh token')) {
        return 'Session expired. Please sign in again.';
      }

      return 'Unauthorized request. Check Firebase rules and token.';
    }

    if (statusCode == 404) {
      return 'Realtime Database endpoint not found (HTTP 404). '
          'Use the exact database URL from Firebase Console > Realtime Database, '
          'then pass --dart-define=FIREBASE_DATABASE_URL=...';
    }

    if (statusCode != null) {
      return 'Database request failed (HTTP $statusCode).';
    }

    return 'Database request failed. Check your network connection.';
  }

  String _extractRemoteError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['error'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is Map<String, dynamic>) {
        final message = value['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      return data.toString();
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data).toString();
    }

    return data?.toString() ?? '';
  }
}
