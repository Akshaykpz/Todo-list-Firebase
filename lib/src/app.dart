import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/todos/presentation/pages/todo_page.dart';

enum _AppRoute {
  splash('/splash'),
  login('/login'),
  home('/home');

  const _AppRoute(this.path);
  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) {
    refreshListenable.value++;
  });
  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    initialLocation: _AppRoute.splash.path,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: _AppRoute.splash.path,
        builder: (_, __) => const _SplashPage(),
      ),
      GoRoute(path: _AppRoute.login.path, builder: (_, __) => const AuthPage()),
      GoRoute(path: _AppRoute.home.path, builder: (_, __) => const TodoPage()),
    ],
    redirect: (_, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == _AppRoute.splash.path;
      final onLogin = location == _AppRoute.login.path;

      final isBootstrapping =
          authState.isLoading && !authState.hasValue && !authState.hasError;
      if (isBootstrapping) {
        return onSplash ? null : _AppRoute.splash.path;
      }

      final isAuthenticated = authState.valueOrNull != null;
      if (!isAuthenticated) {
        if (onSplash) {
          return _AppRoute.login.path;
        }
        return onLogin ? null : _AppRoute.login.path;
      }

      if (onSplash || onLogin) {
        return _AppRoute.home.path;
      }
      return null;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});

class TodoFirebaseApp extends ConsumerWidget {
  const TodoFirebaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Todo Firebase App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
