import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../../core/constants.dart';
import '../../core/entrada_animada.dart';
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
    final logoUrl = context.watch<ProveedorConfig>().logoUrl;
    // Dominio sin tenant (app-mc.vercel.app) = login del control plane:
    // solo cuentas platform_admin ya existentes tienen algo que hacer aquí,
    // así que se ve deliberadamente distinto (negro, marca de PrettyCore,
    // sin Google ni registro) para que quede claro que no es "una tienda
    // más" a la que cualquiera pueda entrar o registrarse.
    final esControlPlane = kTenantIdActivo == null;

    return Scaffold(
      backgroundColor: esControlPlane ? Colors.black : kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EnvolturaFormularioResponsivo(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              EntradaAnimada(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: esControlPlane
                          ? Image.asset(kLogoPrettycoreAsset, height: 56, fit: BoxFit.contain)
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(24)),
                                boxShadow: kNeumorphicShadows,
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(24)),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: logoUrl != null && logoUrl.isNotEmpty
                                      ? Image.network(logoUrl, fit: BoxFit.contain)
                                      : Image.asset(kLogoBarberiaAsset, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      esControlPlane ? 'Panel de control' : 'Bienvenido',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: esControlPlane ? Colors.white : const Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      esControlPlane
                          ? 'Acceso restringido a administradores de la plataforma'
                          : 'Inicia sesión en tu cuenta',
                      style: TextStyle(color: esControlPlane ? Colors.white60 : const Color(0xFF6E6E73)),
                    ),
                  ],
                ),
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
                    esControlPlane
                        ? _CampoOscuro(
                            etiqueta: 'Email',
                            controlador: _correo,
                            tipoTeclado: TextInputType.emailAddress,
                            prefijo: const Icon(Icons.email_outlined, color: Colors.white60),
                            accionTeclado: TextInputAction.next,
                            validador: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu email';
                              if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(v.trim())) return 'Email inválido';
                              return null;
                            },
                          )
                        : CampoTexto(
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
                    esControlPlane
                        ? _CampoOscuro(
                            etiqueta: 'Contraseña',
                            controlador: _contrasena,
                            ocultar: _ocultar,
                            prefijo: const Icon(Icons.lock_outline, color: Colors.white60),
                            sufijo: IconButton(
                              icon: Icon(
                                _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white60,
                              ),
                              onPressed: () => setState(() => _ocultar = !_ocultar),
                            ),
                            accionTeclado: TextInputAction.done,
                            alEnviar: (_) => _enviar(),
                            validador: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              return null;
                            },
                          )
                        : CampoTexto(
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
                            accionTeclado: TextInputAction.done,
                            alEnviar: (_) => _enviar(),
                            validador: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              return null;
                            },
                          ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(color: esControlPlane ? Colors.white70 : null)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BotonPrincipal(
                      etiqueta: 'Iniciar sesión',
                      onPressed: _enviar,
                      cargando: auth.cargando,
                    ),
                  ],
                ),
              ),

              // El resto (Google, registro) no aplica al control plane: ahí
              // solo entran cuentas platform_admin ya creadas de antemano,
              // nunca por autorregistro ni por "cualquier cuenta de Google".
              if (!esControlPlane) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFD1D1D6))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o continúa con',
                          style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFD1D1D6))),
                  ],
                ),
                const SizedBox(height: 16),
                _BotonSocial(
                  onPressed: () => context.read<ProveedorAuth>().iniciarSesionConGoogle(),
                  logo: _LogoGoogle(),
                  etiqueta: 'Continuar con Google',
                  colorBorde: const Color(0xFFD1D1D6),
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
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// ── Campo de texto oscuro (login del control plane) ────────────
class _CampoOscuro extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final bool ocultar;
  final TextInputType? tipoTeclado;
  final String? Function(String?)? validador;
  final Widget? prefijo;
  final Widget? sufijo;
  final TextInputAction? accionTeclado;
  final void Function(String)? alEnviar;

  const _CampoOscuro({
    required this.etiqueta,
    required this.controlador,
    this.ocultar = false,
    this.tipoTeclado,
    this.validador,
    this.prefijo,
    this.sufijo,
    this.accionTeclado,
    this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: ocultar,
      keyboardType: tipoTeclado,
      validator: validador,
      textInputAction: accionTeclado,
      onFieldSubmitted: alEnviar,
      maxLength: ocultar ? 128 : 254,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: prefijo,
        suffixIcon: sufijo,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2C2E))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

// ── Botón social genérico ──────────────────────────────────
class _BotonSocial extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget logo;
  final String etiqueta;
  final Color colorBorde;

  const _BotonSocial({
    required this.onPressed,
    required this.logo,
    required this.etiqueta,
    required this.colorBorde,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: colorBorde, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 10),
            Text(
              etiqueta,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo Google ────────────────────────────────────────────
class _LogoGoogle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'IMG/google_logo.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

