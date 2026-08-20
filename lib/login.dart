import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/auth_repository.dart';
import 'ui/common/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuario = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  final _auth = RepositorioAuth();

  // Colores por defecto
  static const Color colorFondo = Colors.black;
  static const Color colorPrimario = Color(0xFF7C3AED);

  Future<void> _iniciarSesion() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _auth.iniciarSesion(
          correo: _usuario.text.trim(), contrasena: _pass.text);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      String mensajeError = 'Error al iniciar sesión';
      if (e.toString().contains('Invalid login credentials')) {
        mensajeError = 'Usuario o contraseña incorrectos';
      } else if (e.toString().contains('Email not confirmed')) {
        mensajeError = 'Por favor confirma tu correo';
      } else if (e.toString().contains('network')) {
        mensajeError = 'Error de conexión. Verifica tu internet';
      } else if (e.toString().contains('Invalid API key') ||
          e.toString().contains('Invalid Supabase URL')) {
        mensajeError = 'Error de configuración. Contacta al administrador';
      }
      setState(() => _error = mensajeError);
      if (mounted) {
        mostrarToast(context, mensajeError, tipo: TipoToast.error);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _crearCuenta() async {
    if (_usuario.text.isEmpty ||
        !_usuario.text.contains('@') ||
        _pass.text.length < 3) {
      setState(() => _error = 'Correo válido y contraseña (>=3) requeridos.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _auth.registrarse(
          correo: _usuario.text.trim(),
          contrasena: _pass.text,
          nombreCompleto: _usuario.text.trim());
      if (!mounted) return;
      mostrarToast(context, 'Cuenta creada.', tipo: TipoToast.exito);
      context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(
                  painter: _FondoGeom(colorPrimario.withOpacity(0.15)))),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                color: const Color(0xFF1E1E1E),
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LogoDeConfig(logoBase64: null),
                        const SizedBox(height: 8),
                        const Text('Bienvenido',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Inicia sesión o crea tu cuenta',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usuario,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Usuario o Correo',
                            hintText: 'admin o correo@ejemplo.com',
                            hintStyle: const TextStyle(color: Colors.white30),
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingresa tu usuario o correo'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pass,
                          obscureText: _ocultar,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _ocultar = !_ocultar),
                              icon: Icon(_ocultar
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.length < 3)
                              ? 'Mínimo 3 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: Colors.redAccent)),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorPrimario,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _cargando ? null : _iniciarSesion,
                                child: _cargando
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Entrar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: colorPrimario),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                              ),
                              onPressed: _cargando ? null : _crearCuenta,
                              child: const Text('Crear cuenta'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FondoGeom extends CustomPainter {
  final Color color;
  _FondoGeom(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.18)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.28)
      ..lineTo(size.width * 0.3, size.height * 0.42)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoDeConfig extends StatelessWidget {
  final String? logoBase64;
  const _LogoDeConfig({required this.logoBase64});
  @override
  Widget build(BuildContext context) {
    if (logoBase64 == null || logoBase64!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child:
            Text('PRETTYC🟣RE', style: Theme.of(context).textTheme.titleLarge),
      );
    }
    try {
      final Uint8List bytes = base64Decode(logoBase64!);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Image.memory(bytes, height: 44, fit: BoxFit.contain),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
