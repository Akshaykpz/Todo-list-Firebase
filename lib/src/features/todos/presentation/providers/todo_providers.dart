import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/todo_api_service.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/add_todo_usecase.dart';
import '../../domain/usecases/delete_todo_usecase.dart';
import '../../domain/usecases/get_todos_usecase.dart';
import '../../domain/usecases/toggle_todo_usecase.dart';
import '../../domain/usecases/update_todo_usecase.dart';

final todoDatabaseSetupIssueProvider = Provider<String?>((ref) {
  if (Env.firebaseDatabaseUrlOrNull != null) {
    return null;
  }
  return 'Realtime Database URL is missing. '
      'Provide --dart-define=FIREBASE_DATABASE_URL=https://<db-name>.<region>.firebasedatabase.app/';
});

final todoApiServiceProvider = Provider<TodoApiService?>((ref) {
  final dio = ref.watch(dioProvider);
  final databaseUrl = Env.firebaseDatabaseUrlOrNull;
  if (databaseUrl == null) {
    return null;
  }
  return TodoApiService(dio, baseUrl: databaseUrl);
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final apiService = ref.watch(todoApiServiceProvider);
  if (apiService == null) {
    return const _MissingDatabaseUrlTodoRepository();
  }
  return TodoRepositoryImpl(apiService);
});

final getTodosUseCaseProvider = Provider<GetTodosUseCase>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return GetTodosUseCase(repository);
});

final addTodoUseCaseProvider = Provider<AddTodoUseCase>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return AddTodoUseCase(repository);
});

final toggleTodoUseCaseProvider = Provider<ToggleTodoUseCase>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return ToggleTodoUseCase(repository);
});

final updateTodoUseCaseProvider = Provider<UpdateTodoUseCase>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return UpdateTodoUseCase(repository);
});

final deleteTodoUseCaseProvider = Provider<DeleteTodoUseCase>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return DeleteTodoUseCase(repository);
});

final todoControllerProvider =
    AsyncNotifierProvider<TodoController, List<Todo>>(TodoController.new);

class TodoController extends AsyncNotifier<List<Todo>> {
  @override
  FutureOr<List<Todo>> build() async {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) {
      return const <Todo>[];
    }

    final useCase = ref.watch(getTodosUseCaseProvider);
    try {
      return await useCase(user);
    } catch (error) {
      await _handleUnauthorized(error);
      return const <Todo>[];
    }
  }

  Future<void> refreshTodos() async {
    final user = _requireUser();
    final useCase = ref.read(getTodosUseCaseProvider);
    final previous = state.valueOrNull ?? const <Todo>[];
    try {
      final todos = await useCase(user);
      state = AsyncData(todos);
    } catch (error) {
      await _handleUnauthorized(error);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> addTodo(String title) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return;
    }

    final user = _requireUser();
    final previous = state.valueOrNull ?? const <Todo>[];
    final useCase = ref.read(addTodoUseCaseProvider);
    final tempId = '__temp-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticTodo = Todo(
      id: tempId,
      title: normalizedTitle,
      isCompleted: false,
      createdAt: DateTime.now().toUtc(),
    );

    state = AsyncData(<Todo>[optimisticTodo, ...previous]);

    try {
      final createdTodo = await useCase(user, normalizedTitle);
      final current = state.valueOrNull ?? const <Todo>[];
      var wasReplaced = false;
      final updated = current
          .map((todo) {
            if (todo.id == tempId) {
              wasReplaced = true;
              return createdTodo;
            }
            return todo;
          })
          .toList(growable: true);
      if (!wasReplaced) {
        updated.insert(0, createdTodo);
      }
      state = AsyncData(updated.toList(growable: false));
    } catch (error) {
      await _handleUnauthorized(error);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateTodo(Todo todo, String title) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || normalizedTitle == todo.title) {
      return;
    }

    final user = _requireUser();
    final previous = state.valueOrNull ?? const <Todo>[];
    final useCase = ref.read(updateTodoUseCaseProvider);
    final updatedTodo = todo.copyWith(title: normalizedTitle);

    state = AsyncData(
      previous
          .map((item) => item.id == todo.id ? updatedTodo : item)
          .toList(growable: false),
    );

    try {
      await useCase(user, updatedTodo);
    } catch (error) {
      await _handleUnauthorized(error);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> toggleTodo(Todo todo) async {
    final user = _requireUser();
    final previous = state.valueOrNull ?? const <Todo>[];
    final useCase = ref.read(toggleTodoUseCaseProvider);

    final optimistic = previous
        .map(
          (item) => item.id == todo.id
              ? item.copyWith(isCompleted: !item.isCompleted)
              : item,
        )
        .toList(growable: false);

    state = AsyncData(optimistic);
    try {
      await useCase(user, todo);
    } catch (error) {
      await _handleUnauthorized(error);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteTodo(String todoId) async {
    final user = _requireUser();
    final previous = state.valueOrNull ?? const <Todo>[];
    final useCase = ref.read(deleteTodoUseCaseProvider);

    state = AsyncData(
      previous.where((todo) => todo.id != todoId).toList(growable: false),
    );

    try {
      await useCase(user, todoId);
    } catch (error) {
      await _handleUnauthorized(error);
      state = AsyncData(previous);
      rethrow;
    }
  }

  AppUser _requireUser() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      throw const AppException('You must be signed in to manage todos.');
    }
    return user;
  }

  Future<void> _handleUnauthorized(Object error) async {
    final normalized = error.toString().toLowerCase();
    final isSessionInvalid =
        normalized.contains('session expired') ||
        normalized.contains('token expired') ||
        normalized.contains('invalid id token') ||
        normalized.contains('invalid refresh token') ||
        normalized.contains('id token is expired');
    if (!isSessionInvalid) {
      return;
    }
    await ref.read(authControllerProvider.notifier).invalidateSession();
  }
}

class _MissingDatabaseUrlTodoRepository implements TodoRepository {
  const _MissingDatabaseUrlTodoRepository();

  @override
  Future<List<Todo>> fetchTodos({
    required String userId,
    required String idToken,
  }) async {
    return const <Todo>[];
  }

  @override
  Future<Todo> addTodo({
    required String userId,
    required String idToken,
    required String title,
  }) {
    throw const AppException(
      'Realtime Database URL is missing. '
      'Pass --dart-define=FIREBASE_DATABASE_URL=...',
    );
  }

  @override
  Future<void> updateTodo({
    required String userId,
    required String idToken,
    required Todo todo,
  }) {
    throw const AppException(
      'Realtime Database URL is missing. '
      'Pass --dart-define=FIREBASE_DATABASE_URL=...',
    );
  }

  @override
  Future<void> deleteTodo({
    required String userId,
    required String idToken,
    required String todoId,
  }) {
    throw const AppException(
      'Realtime Database URL is missing. '
      'Pass --dart-define=FIREBASE_DATABASE_URL=...',
    );
  }
  
}
