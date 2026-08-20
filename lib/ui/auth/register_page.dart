import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({super.key});

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  final _claveFormulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmContrasena = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _contrasena.dispose();
    _confirmContrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    final auth = context.read<ProveedorAuth>();
    final exito = await auth.registrarse(
      correo: _correo.text.trim(),
      contrasena: _contrasena.text,
      nombreCompleto: _nombre.text.trim(),
      telefono: _telefono.text.trim(),
    );
    if (exito && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProveedorAuth>();

    return Scaffold(
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
                      'Crea tu cuenta',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Completa los datos para registrarte',
                      style: TextStyle(color: Color(0xFF6E6E73)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (auth.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              Form(
                key: _claveFormulario,
                child: Column(
                  children: [
                    CampoTexto(
                      etiqueta: 'Nombre completo',
                      controlador: _nombre,
                      prefijo: const Icon(Icons.person_outline, color: kTextSub),
                      accionTeclado: TextInputAction.next,
                      validador: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Email',
                      controlador: _correo,
                      tipoTeclado: TextInputType.emailAddress,
                      prefijo: const Icon(Icons.email_outlined, color: kTextSub),
                      accionTeclado: TextInputAction.next,
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu email';
                        if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(v.trim())) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Teléfono (opcional)',
                      controlador: _telefono,
                      tipoTeclado: TextInputType.phone,
                      prefijo: const Icon(Icons.phone_outlined, color: kTextSub),
                      accionTeclado: TextInputAction.next,
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
                      accionTeclado: TextInputAction.next,
                      validador: (v) {
                        if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Confirmar contraseña',
                      controlador: _confirmContrasena,
                      ocultar: _ocultar,
                      prefijo: const Icon(Icons.lock_outline, color: kTextSub),
                      accionTeclado: TextInputAction.done,
                      alEnviar: (_) => _enviar(),
                      validador: (v) {
                        if (v != _contrasena.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    BotonPrincipal(
                      etiqueta: 'Crear cuenta',
                      onPressed: _enviar,
                      cargando: auth.cargando,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta? ', style: TextStyle(color: Color(0xFF6E6E73))),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Inicia sesión'),
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
