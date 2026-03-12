import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class PaginaMuroInvitado extends StatelessWidget {
  final String mensaje;
  const PaginaMuroInvitado({
    super.key,
    this.mensaje = 'Inicia sesión para continuar',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colorPrimario.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 56, color: context.colorPrimario),
              ),
              const SizedBox(height: 24),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una cuenta o inicia sesión para acceder a esta sección.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSub, fontSize: 14),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Iniciar sesión',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorPrimario,
                    side: BorderSide(color: context.colorPrimario),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Registrarse',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra un bottom sheet de login/registro.
/// Retorna true si el usuario inició sesión.
void mostrarLoginRequerido(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: kTextMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 40, color: context.colorPrimario),
          const SizedBox(height: 12),
          const Text('Acción requerida',
              style: TextStyle(
                  color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Debes iniciar sesión o registrarte para realizar esta acción.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSub, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Iniciar sesión',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/register');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colorPrimario,
                side: BorderSide(color: context.colorPrimario),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Registrarse',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
