import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_page_ui_provider.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form_card.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  late final ProviderSubscription<AsyncValue<AppUser?>> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AsyncValue<AppUser?>>(
      authControllerProvider,
      (_, next) {
        next.whenOrNull(
          error: (error, _) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.toString())));
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authPageUiControllerProvider);
    final uiController = ref.read(authPageUiControllerProvider.notifier);
    final isLoading = ref.watch(
      authControllerProvider.select((state) => state.isLoading),
    );
    final viewInsets = MediaQuery.viewInsetsOf(context);

    Future<void> submit() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final wasSignInMode = uiState.isSignInMode;
      final messenger = ScaffoldMessenger.maybeOf(context);
      FocusScope.of(context).unfocus();
      try {
        await uiController.submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (error) {
        if (!mounted) {
          return;
        }

        messenger?.showSnackBar(SnackBar(content: Text(error.toString())));
        return;
      }
      if (!mounted) {
        return;
      }
      if (wasSignInMode) {
        return;
      }
      final authState = ref.read(authControllerProvider);
      final isSuccess = !authState.hasError && authState.valueOrNull != null;
      if (isSuccess) {

        messenger?.showSnackBar(
          const SnackBar(content: Text('Account created successfully.')),
        );
        
      }
    }

    Future<void> continueWithGoogle() async {
      FocusScope.of(context).unfocus();
      await uiController.continueWithGoogle();
    }

    void toggleMode() {
      FocusScope.of(context).unfocus();
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      uiController.toggleMode();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEDEBFF), Color(0xFFF8F7FF), Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 700;
                final availableHeight =
                    constraints.maxHeight - viewInsets.bottom;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    isCompact ? 16 : 28,
                    20,
                    24 + viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight > 0 ? availableHeight - 36 : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AuthFormCard(
                          formKey: _formKey,
                          isSignInMode: uiState.isSignInMode,
                          isLoading: isLoading,
                          obscurePassword: uiState.obscurePassword,
                          obscureConfirmPassword:
                              uiState.obscureConfirmPassword,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          onContinueWithGoogle: continueWithGoogle,
                          onSubmit: submit,
                          onToggleMode: toggleMode,
                          onTogglePasswordVisibility:
                              uiController.togglePasswordVisibility,
                          onToggleConfirmPasswordVisibility:
                              uiController.toggleConfirmPasswordVisibility,
                          validateEmail: uiController.validateEmail,
                          validatePassword: uiController.validatePassword,
                          validateConfirmPassword: (value) =>
                              uiController.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                          onPasswordFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                          onConfirmPasswordFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
