import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';

typedef AuthenticateCallback = Future<void> Function({
  required String email,
  required String password,
  required bool register,
  String? firstName,
});

class LoginScreen extends StatefulWidget {
  final AuthenticateCallback onAuthenticate;
  final VoidCallback onLogin;

  const LoginScreen({
    super.key,
    required this.onAuthenticate,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();

  bool _registerMode = false;
  bool _passwordVisible = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Introduce tu correo electrónico.';
    if (email.length > 320 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Introduce un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Introduce tu contraseña.';
    if (password.length > 128) return 'La contraseña no puede superar 128 caracteres.';
    if (_registerMode && password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  String? _validateFirstName(String? value) {
    if (!_registerMode) return null;
    final firstName = (value ?? '').trim();
    if (firstName.isEmpty) return 'Introduce tu nombre.';
    if (firstName.length > 80) return 'El nombre no puede superar 80 caracteres.';
    return null;
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'Revisa los datos introducidos e inténtalo de nuevo.';
        case 401:
          return 'El correo o la contraseña no son correctos.';
        case 409:
          return 'Ya existe una cuenta con ese correo electrónico.';
        case 429:
          return 'Demasiados intentos. Espera un minuto antes de volver a intentarlo.';
        case 500:
        case 502:
        case 503:
          return 'El servicio no está disponible ahora mismo. Inténtalo más tarde.';
        default:
          return 'No se ha podido completar la operación. Inténtalo de nuevo.';
      }
    }
    if (error is TimeoutException) {
      return 'La conexión ha tardado demasiado. Comprueba tu conexión e inténtalo otra vez.';
    }
    return 'No se ha podido conectar con Diabeta. Comprueba tu conexión e inténtalo otra vez.';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onAuthenticate(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        register: _registerMode,
        firstName: _registerMode ? _firstName.text.trim() : null,
      );
      if (mounted) widget.onLogin();
    } catch (error) {
      debugPrint('Diabeta auth failed (' + error.runtimeType.toString() + ').');
      if (mounted) setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toggleMode() {
    if (_submitting) return;
    setState(() {
      _registerMode = !_registerMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.monitor_heart_outlined, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            'Diabeta',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _registerMode
                                ? 'Crea tu cuenta segura'
                                : 'Inicia sesión para continuar',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          if (_registerMode) ...[
                            TextFormField(
                              key: const Key('auth-first-name'),
                              controller: _firstName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                              maxLength: 80,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateFirstName,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            key: const Key('auth-email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 320,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _password,
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: [
                              _registerMode
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 128,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                key: const Key('auth-toggle-password'),
                                tooltip: _passwordVisible
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible,
                                ),
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _errorMessage!,
                                key: const Key('auth-error'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            key: const Key('auth-submit'),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_registerMode ? 'Crear cuenta' : 'Entrar'),
                          ),
                          TextButton(
                            key: const Key('auth-toggle-mode'),
                            onPressed: _submitting ? null : _toggleMode,
                            child: Text(
                              _registerMode
                                  ? 'Ya tengo cuenta · Iniciar sesión'
                                  : '¿No tienes cuenta? Crear una cuenta',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diabeta es una herramienta de apoyo informativo y no sustituye la atención sanitaria.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
