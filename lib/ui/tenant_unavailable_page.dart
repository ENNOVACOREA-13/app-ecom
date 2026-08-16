import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Pantalla mostrada en vez de la app cuando el control plane resuelve un
/// tenant con status distinto de 'active' (p. ej. 'suspended'). Deliberadamente
/// standalone (su propio MaterialApp, sin Provider/routing de BarberApp) ya
/// que se muestra ANTES de que Supabase.initialize corra para ese dominio.
class PaginaTenantNoDisponible extends StatelessWidget {
  final String? businessName;

  const PaginaTenantNoDisponible({super.key, this.businessName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, size: 56, color: Color(0xFF8E8E93)),
                const SizedBox(height: 20),
                const Text(
                  'Este sitio no está disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 8),
                Text(
                  businessName != null
                      ? 'La cuenta de $businessName no está activa en este momento.'
                      : 'Esta cuenta no está activa en este momento.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6E6E73)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
