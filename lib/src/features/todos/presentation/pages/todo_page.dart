import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_page_controller_provider.dart';
import '../providers/todo_providers.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/issue_banner.dart';
import '../widgets/list_header.dart';
import '../widgets/progress_section.dart';
import '../widgets/task_card.dart';




class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = ref.read(todoPageControllerProvider);
    final email = ref.watch(
      authControllerProvider.select((state) => state.valueOrNull?.email),
    );
    final todosState = ref.watch(todoControllerProvider);
    final todos = todosState.valueOrNull ?? const <Todo>[];
    final setupIssue = ref.watch(todoDatabaseSetupIssueProvider);
    final completedCount = todos.where((todo) => todo.isCompleted).length;
    final progress = todos.isEmpty ? 0.0 : completedCount / todos.length;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.small(
        onPressed: setupIssue == null
            ? () => pageController.openCreateTaskDialog(context)
            : null,
        backgroundColor: TodoPageController.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 34, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => pageController.refreshTodosWithFeedback(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: DashboardHeader(
                    email: email ?? 'Dashboard',
                    onSignOut: () => pageController.confirmAndSignOut(context),
                    primaryColor: TodoPageController.primaryColor,
                  ),
                ),
              ),
              if (setupIssue != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: IssueBanner(message: setupIssue),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: ProgressSection(
                    completedCount: completedCount,
                    totalCount: todos.length,
                    progress: progress,
                    primaryColor: TodoPageController.primaryColor,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: ListHeader(count: todos.length),
                ),
              ),
              if (todosState.isLoading && todos.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: LinearProgressIndicator(),
                  ),
                ),
              if (todosState.isLoading && todos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (todos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: EmptyStateCard(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  sliver: SliverList.separated(
                    itemBuilder: (_, index) {
                      final todo = todos[index];
                      final isActionLocked = pageController.isActionLocked(
                        setupIssue: setupIssue,
                        todo: todo,
                      );
                      return TaskCard(
                        todo: todo,
                        color: pageController.taskCardColor(
                          index,
                          todo.isCompleted,
                        ),
                        setupLocked: isActionLocked,
                        onToggle: () => pageController.toggleTodoWithFeedback(
                          context,
                          todo,
                        ),
                        onEdit: () =>
                            pageController.openEditTaskDialog(context, todo),
                        onDelete: () => pageController.deleteTodoWithFeedback(
                          context,
                          todo.id,
                        ),
                      );
                    },
                    itemCount: todos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
    );
  }
}
