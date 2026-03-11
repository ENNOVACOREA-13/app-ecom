import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  final _claveFormulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    final auth = context.read<ProveedorAuth>();
    final exito = await auth.iniciarSesion(_correo.text.trim(), _contrasena.text);
    if (exito && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProveedorAuth>();

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Logo — dark card with glow
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    boxShadow: kNeumorphicShadows,
                  ),
                  child: const Icon(Icons.content_cut, color: kPrimary, size: 36),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Bienvenido',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión en tu cuenta',
                style: TextStyle(color: Color(0xFF6E6E73)),
              ),
              const SizedBox(height: 40),

              if (auth.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _claveFormulario,
                child: Column(
                  children: [
                    CampoTexto(
                      etiqueta: 'Email',
                      controlador: _correo,
                      tipoTeclado: TextInputType.emailAddress,
                      prefijo: const Icon(Icons.email_outlined, color: kTextSub),
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu email';
                        if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(v.trim())) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Contraseña',
                      controlador: _contrasena,
                      ocultar: _ocultar,
                      prefijo: const Icon(Icons.lock_outline, color: kTextSub),
                      sufijo: IconButton(
                        icon: Icon(
                          _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: kTextSub,
                        ),
                        onPressed: () => setState(() => _ocultar = !_ocultar),
                      ),
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      etiqueta: 'Iniciar sesión',
                      onPressed: _enviar,
                      cargando: auth.cargando,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta? ', style: TextStyle(color: Color(0xFF6E6E73))),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Regístrate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
