import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/todo.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/logout_confirm_dialog.dart';
import 'todo_providers.dart';

final todoPageControllerProvider = Provider<TodoPageController>(
  (ref) => TodoPageController(ref),
);

class TodoPageController {
  const TodoPageController(this._ref);

  static const primaryColor = Color(0xFF5D63F3);

  final Ref _ref;

  Future<void> refreshTodos() {
    return _ref.read(todoControllerProvider.notifier).refreshTodos();
  }

  Future<void> addTodo(String title) {
    return _ref.read(todoControllerProvider.notifier).addTodo(title);
  }

  Future<void> toggleTodo(Todo todo) {
    return _ref.read(todoControllerProvider.notifier).toggleTodo(todo);
  }

  Future<void> deleteTodo(String todoId) {
    return _ref.read(todoControllerProvider.notifier).deleteTodo(todoId);
  }

  Future<void> updateTodo(Todo todo, String title) {
    return _ref.read(todoControllerProvider.notifier).updateTodo(todo, title);
  }

  Future<void> signOut() {
    return _ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> refreshTodosWithFeedback(BuildContext context) {
    return _runWithFeedback(context, refreshTodos);
  }

  Future<void> openCreateTaskDialog(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const CreateTaskDialog(primary: primaryColor),
    );
    if (!context.mounted) {
      return;
    }

    final normalizedTitle = (title ?? '').trim();
    if (normalizedTitle.isEmpty) {
      return;
    }

    await _runWithFeedback(context, () => addTodo(normalizedTitle));
  }

  Future<void> openEditTaskDialog(BuildContext context, Todo todo) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => CreateTaskDialog(
        primary: primaryColor,
        dialogTitle: 'Edit Task',
        submitLabel: 'Save',
        initialTitle: todo.title,
      ),
    );
    if (!context.mounted) {
      return;
    }

    final normalizedTitle = (title ?? '').trim();
    if (normalizedTitle.isEmpty || normalizedTitle == todo.title) {
      return;
    }

    await _runWithFeedback(context, () => updateTodo(todo, normalizedTitle));
  }

  Future<void> confirmAndSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const LogoutConfirmDialog(),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await _runWithFeedback(context, signOut);
  }

  Future<void> toggleTodoWithFeedback(BuildContext context, Todo todo) {
    return _runWithFeedback(context, () => toggleTodo(todo));
  }

  Future<void> deleteTodoWithFeedback(BuildContext context, String todoId) {
    return _runWithFeedback(context, () => deleteTodo(todoId));
  }

  bool isActionLocked({required String? setupIssue, required Todo todo}) {
    return setupIssue != null || todo.id.startsWith('__temp-');
  }

  Color taskCardColor(int index, bool done) {
    if (done) {
      return const Color(0xFFE7F3EA);
    }
    const palette = [
      Color(0xFFFCECF2),
      Color(0xFFE6F2FB),
      Color(0xFFF8F0E2),
      Color(0xFFEDEBFF),
    ];
    return palette[index % palette.length];
  }

  Future<void> _runWithFeedback(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger?.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
