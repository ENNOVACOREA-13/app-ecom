import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaOlvideContrasena extends StatefulWidget {
  const PaginaOlvideContrasena({super.key});

  @override
  State<PaginaOlvideContrasena> createState() => _PaginaOlvideContrasenaState();
}

class _PaginaOlvideContrasenaState extends State<PaginaOlvideContrasena> {
  final _claveFormulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    await context.read<ProveedorAuth>().solicitarRecuperacionContrasena(_correo.text.trim());
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _enviado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EnvolturaFormularioResponsivo(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntradaAnimada(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tu correo y te mandamos un enlace para restablecerla.',
                      style: TextStyle(color: Color(0xFF6E6E73)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_enviado)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña. Revisa tu bandeja (y spam).',
                          style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: _claveFormulario,
                  child: Column(
                    children: [
                      CampoTexto(
                        etiqueta: 'Email',
                        controlador: _correo,
                        tipoTeclado: TextInputType.emailAddress,
                        prefijo: const Icon(Icons.email_outlined, color: kTextSub),
                        accionTeclado: TextInputAction.done,
                        alEnviar: (_) => _enviar(),
                        validador: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu email';
                          if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(v.trim())) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BotonPrincipal(
                        etiqueta: 'Enviar enlace',
                        onPressed: _enviar,
                        cargando: _enviando,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Volver a iniciar sesión'),
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
