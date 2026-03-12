import 'package:flutter/material.dart';

import 'auth_logo.dart';
import 'auth_text_field.dart';
import 'google_badge.dart';
import 'or_divider.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.formKey,
    required this.isSignInMode,
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onContinueWithGoogle,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.onPasswordFieldSubmitted,
    required this.onConfirmPasswordFieldSubmitted,
  });

  final GlobalKey<FormState> formKey;
  final bool isSignInMode;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onContinueWithGoogle;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;
  final ValueChanged<String> onPasswordFieldSubmitted;
  final ValueChanged<String> onConfirmPasswordFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A3D4280),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthLogo(),
              const SizedBox(height: 14),
              Text(
                isSignInMode ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1F2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSignInMode
                    ? 'Welcome back. Continue to your tasks.'
                    : 'Create your account and start tracking tasks.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF6C7184),
                ),
              ),
              const SizedBox(height: 16),
              if (isSignInMode) ...[
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onContinueWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD8DBEA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GoogleBadge(),
                        SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2430),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const OrDivider(),
                const SizedBox(height: 16),
              ],
              AuthTextField(
                controller: emailController,
                label: 'Email',
                hint: 'enter your email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: passwordController,
                label: 'Password',
                hint: 'enter your password',
                textInputAction: isSignInMode
                    ? TextInputAction.done
                    : TextInputAction.next,
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  onPressed: onTogglePasswordVisibility,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: validatePassword,
                onFieldSubmitted: onPasswordFieldSubmitted,
              ),
              if (!isSignInMode) ...[
                const SizedBox(height: 12),
                AuthTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    onPressed: onToggleConfirmPasswordVisibility,
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: validateConfirmPassword,
                  onFieldSubmitted: onConfirmPasswordFieldSubmitted,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5D63F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isSignInMode ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: isLoading ? null : onToggleMode,
                child: Text(
                  isSignInMode
                      ? 'Need an account? Sign up'
                      : 'Already have an account? Sign in',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
