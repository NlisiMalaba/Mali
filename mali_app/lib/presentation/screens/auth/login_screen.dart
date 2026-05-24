import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart';
import 'package:mali_app/presentation/auth/auth_form_validators.dart';
import 'package:mali_app/presentation/widgets/auth/auth_password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();

  final _contactFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void initState() {
    super.initState();
    _contactFocus.addListener(() => _handleBlur('contact', _contactFocus));
    _passwordFocus.addListener(() => _handleBlur('password', _passwordFocus));
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    _contactFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleBlur(String field, FocusNode focusNode) {
    if (!focusNode.hasFocus && mounted) {
      setState(() => _touchedFields.add(field));
      _formKey.currentState?.validate();
    }
  }

  bool _isTouched(String field) => _submitted || _touchedFields.contains(field);

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touchedFields
        ..add('contact')
        ..add('password');
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final contact = _contactController.text.trim();
    final password = _passwordController.text;
    final input = AuthFormValidators.looksLikeEmail(contact)
        ? LoginInput(password: password, email: contact)
        : LoginInput(password: password, phone: contact);

    await ref.read(authProvider.notifier).login(input);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loginErrorMessage(authState.error))),
      );
      return;
    }

    if (authState.hasValue && authState.value != null) {
      context.go('/home');
    }
  }

  String _loginErrorMessage(Object? error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Invalid email/phone or password.';
      }
      if (statusCode == 400) {
        return 'Check your details and try again.';
      }
      return 'Sign in failed. Check your connection and try again.';
    }

    return 'Invalid email/phone or password.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue managing your wallets.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _contactController,
                  focusNode: _contactFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email or phone number',
                  ),
                  validator: (value) => AuthFormValidators.loginContact(
                    value,
                    touched: _isTouched('contact'),
                  ),
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 20),
                AuthPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  labelText: 'Password',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => AuthFormValidators.loginPassword(
                    value,
                    touched: _isTouched('password'),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () {},
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Mali?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/auth/register'),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
