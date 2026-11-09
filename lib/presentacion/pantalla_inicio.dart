import 'package:flutter/material.dart';

import '../datos/autenticacion/auth_client.dart';
import '../datos/multijugador/multiplayer_client.dart';
import 'pantalla_cuenta.dart';
import 'pantalla_instrucciones.dart';
import 'pantalla_multijugador.dart';
import 'seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'tema_mesa.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({this.authGateway, this.multiplayerClient, super.key});

  final AuthGateway? authGateway;
  final MultiplayerClient? multiplayerClient;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  AuthGateway get _authGateway => widget.authGateway ?? AuthClient.shared;

  AuthUser? _user;
  String? _sessionError;
  bool _canRetrySession = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _authGateway.currentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _sessionError = null;
          _canRetrySession = false;
        });
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _user = null;
          _sessionError = error.userMessage;
          _canRetrySession = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retrySession() async {
    setState(() => _isLoading = true);
    await _restoreSession();
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PantallaCuenta(
          authGateway: _authGateway,
          closeOnAuthentication: _user == null,
        ),
      ),
    );
    if (mounted) {
      setState(() => _isLoading = true);
      await _restoreSession();
    }
  }

  void _openInstructions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaInstrucciones()),
    );
  }

  void _openMaps() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaSeleccionMapa()),
    );
  }

  void _openMultiplayer() {
    final user = _user;
    if (user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PantallaMultijugador(user: user, client: widget.multiplayerClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final anchoMaximo = constraints.maxWidth < 720 ? 520.0 : 760.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: anchoMaximo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.94, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [TemaMesa.verde, Color(0xFF294D32)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: TemaMesa.dorado,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33402C20),
                                blurRadius: 16,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: TemaMesa.papelClaro,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: TemaMesa.dorado,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.casino_rounded,
                                  size: 38,
                                  color: TemaMesa.nogal,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Brilliant',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: TemaMesa.papelClaro,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Una partida de ingenio y estrategia',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFF0DFC0),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: IndicadorCargaMesa(
                            mensaje: 'Preparando tu mesa...',
                          ),
                        )
                      else if (_user == null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  _sessionError == null
                                      ? Icons.auto_awesome
                                      : Icons.cloud_off_outlined,
                                  color: TemaMesa.verde,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sessionError ?? 'Crea una cuenta o inicia sesión para jugar.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_canRetrySession)
                          TextButton.icon(
                            key: const Key('retry-session'),
                            onPressed: _isLoading ? null : _retrySession,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar conexión'),
                          ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  color: TemaMesa.verde,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '¡Hola, ${_user!.name}!',
                                    key: const Key('welcome-user-name'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _openInstructions,
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Instrucciones'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _openAccount,
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          _user == null
                              ? 'Crear cuenta o iniciar sesión'
                              : 'Mi cuenta',
                        ),
                      ),
                      if (_user != null) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _openMaps,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Jugar',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('open-multiplayer'),
                          onPressed: _openMultiplayer,
                          icon: const Icon(Icons.groups_outlined),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Multijugador',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
