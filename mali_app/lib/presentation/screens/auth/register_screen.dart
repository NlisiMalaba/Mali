import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart';
import 'package:mali_app/presentation/auth/auth_form_validators.dart';
import 'package:mali_app/presentation/widgets/auth/auth_password_field.dart';

enum _ContactMethod { email, phone }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  _ContactMethod _contactMethod = _ContactMethod.email;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => _handleBlur('name', _nameFocus));
    _contactFocus.addListener(() => _handleBlur('contact', _contactFocus));
    _passwordFocus.addListener(() => _handleBlur('password', _passwordFocus));
    _confirmPasswordFocus.addListener(
      () => _handleBlur('confirmPassword', _confirmPasswordFocus),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _contactFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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
        ..add('name')
        ..add('contact')
        ..add('password')
        ..add('confirmPassword');
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text;

    final input = _contactMethod == _ContactMethod.email
        ? RegisterInput(name: name, password: password, email: contact)
        : RegisterInput(name: name, password: password, phone: contact);

    await ref.read(authProvider.notifier).register(input);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      final message = _registrationErrorMessage(authState.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (authState.hasValue && authState.value != null) {
      context.go('/home');
    }
  }

  String _registrationErrorMessage(Object? error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 409) {
        return 'An account with this email or phone already exists.';
      }
      if (statusCode == 400) {
        return 'Check your details and try again.';
      }
      return 'Registration failed. Check your connection and try again.';
    }

    return 'Registration failed. Please try again.';
  }

  void _switchContactMethod(_ContactMethod method) {
    if (_contactMethod == method) return;

    setState(() {
      _contactMethod = method;
      _contactController.clear();
      _touchedFields.remove('contact');
    });
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Track spending across wallets and currencies in one place.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                  validator: (value) => AuthFormValidators.name(
                    value,
                    touched: _isTouched('name'),
                  ),
                  onFieldSubmitted: (_) => _contactFocus.requestFocus(),
                ),
                const SizedBox(height: 20),
                SegmentedButton<_ContactMethod>(
                  segments: const [
                    ButtonSegment(
                      value: _ContactMethod.email,
                      label: Text('Email'),
                      icon: Icon(Icons.email_outlined),
                    ),
                    ButtonSegment(
                      value: _ContactMethod.phone,
                      label: Text('Phone'),
                      icon: Icon(Icons.phone_outlined),
                    ),
                  ],
                  selected: {_contactMethod},
                  onSelectionChanged: (selection) {
                    _switchContactMethod(selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  focusNode: _contactFocus,
                  keyboardType: _contactMethod == _ContactMethod.email
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: _contactMethod == _ContactMethod.email
                      ? const [AutofillHints.email]
                      : const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: _contactMethod == _ContactMethod.email
                        ? 'Email address'
                        : 'Phone number',
                  ),
                  validator: (value) {
                    if (_contactMethod == _ContactMethod.email) {
                      return AuthFormValidators.email(
                        value,
                        touched: _isTouched('contact'),
                      );
                    }
                    return AuthFormValidators.phone(
                      value,
                      touched: _isTouched('contact'),
                    );
                  },
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 20),
                AuthPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  labelText: 'Password',
                  textInputAction: TextInputAction.next,
                  validator: (value) => AuthFormValidators.password(
                    value,
                    touched: _isTouched('password'),
                  ),
                  onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),
                const SizedBox(height: 20),
                AuthPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  labelText: 'Confirm password',
                  textInputAction: TextInputAction.done,
                  validator: (value) => AuthFormValidators.confirmPassword(
                    value,
                    touched: _isTouched('confirmPassword'),
                    password: _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/auth/login'),
                      child: const Text('Sign in'),
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
