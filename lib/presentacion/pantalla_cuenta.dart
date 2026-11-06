import 'package:flutter/material.dart';

import '../datos/autenticacion/auth_client.dart';

class PantallaCuenta extends StatefulWidget {
  const PantallaCuenta({
    required this.authGateway,
    this.closeOnAuthentication = false,
    super.key,
  });

  final AuthGateway authGateway;
  final bool closeOnAuthentication;

  @override
  State<PantallaCuenta> createState() => _PantallaCuentaState();
}

class _PantallaCuentaState extends State<PantallaCuenta> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthUser? _user;
  bool _isRegistering = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await widget.authGateway.currentUser();
      if (mounted) setState(() => _user = user);
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _isRegistering
          ? await widget.authGateway.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await widget.authGateway.signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (mounted) {
        setState(() => _user = user);
        _passwordController.clear();
        if (widget.closeOnAuthentication) {
          Navigator.of(context).pop();
        }
      }
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await widget.authGateway.signOut();
      if (mounted) setState(() => _user = null);
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() => _user = null);
        final sessionMessage = error.statusCode == 401
            ? 'La sesión del servidor ya no era válida.'
            : 'Se cerró la sesión en este dispositivo, pero no se pudo '
                  'confirmar con el servidor. La sesión remota podría seguir '
                  'activa.';
        _showMessage('$sessionMessage\n${error.userMessage}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    var password = '';
    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es permanente. Confirma tu contraseña para borrar '
              'la cuenta.',
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              obscureText: true,
              onChanged: (value) => password = value,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(password),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Borrar definitivamente'),
          ),
        ],
      ),
    );
    if (confirmedPassword == null || !mounted) return;
    if (confirmedPassword.isEmpty) {
      _showMessage('Ingresa tu contraseña para confirmar el borrado.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authGateway.deleteAccount(confirmedPassword);
      if (mounted) {
        setState(() => _user = null);
        _showMessage('Tu cuenta fue borrada.');
      }
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth < 720 ? 520.0 : 600.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _user == null
                      ? _buildForm()
                      : _buildAccount(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isRegistering ? 'Crear cuenta' : 'Iniciar sesión',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isRegistering) ...[
            TextFormField(
              key: const Key('account-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                helperText: 'Debe ser único; otras personas no pueden usarlo.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (_isRegistering && name.length < 2) {
                  return 'Ingresa un nombre de usuario de al menos 2 caracteres.';
                }
                if (_isRegistering && name.length > 32) {
                  return 'El nombre de usuario no puede superar 32 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('account-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Ingresa un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('account-password'),
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: _isRegistering
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final password = value ?? '';
              if (_isRegistering && password.length < 12) {
                return 'Usa al menos 12 caracteres.';
              }
              if (password.isEmpty) return 'Ingresa tu contraseña.';
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: Text(_isRegistering ? 'Crear cuenta' : 'Iniciar sesión'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                    _isRegistering = !_isRegistering;
                    _formKey.currentState?.reset();
                  }),
            child: Text(
              _isRegistering
                  ? '¿Ya tienes cuenta? Inicia sesión'
                  : '¿No tienes cuenta? Regístrate',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sesión iniciada',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _user!.name,
          key: const Key('account-user-name'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_user!.email, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: _isLoading ? null : _signOut,
          child: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isLoading ? null : _deleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar cuenta'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
