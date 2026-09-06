import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      controller.signUp(email, password);
    } else {
      controller.signIn(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watching the controller lets us show a spinner while a request is
    // in flight and surface any error below the form.
    final authControllerState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isSignUp ? 'Create account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spaceLg),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: AppConstants.spaceLg),
                  if (authControllerState.hasError)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spaceMd),
                      child: Text(
                        _friendlyAuthError(authControllerState.error),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  AppButton(
                    label: _isSignUp ? 'Sign up' : 'Sign in',
                    isLoading: authControllerState.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppConstants.spaceSm),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : "Don't have an account? Sign up",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyAuthError(Object? error) {
    // FirebaseAuthException has a `.code` you can switch on for nicer
    // messages (e.g. 'user-not-found', 'wrong-password', 'weak-password').
    // Kept generic here so this file doesn't need the firebase_auth import
    // just for error mapping — move this into AuthRepository if it grows.
    return 'Something went wrong. Please check your details and try again.';
  }
}
