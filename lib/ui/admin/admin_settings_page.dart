import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import 'manage_services_page.dart';
import 'manage_employees_page.dart';
import 'manage_products_page.dart';
import '../products/products_page.dart';

class PaginaConfigAdmin extends StatelessWidget {
  const PaginaConfigAdmin({super.key});

  Future<void> _salir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await context.read<ProveedorAuth>().cerrarSesion();
      if (context.mounted) context.go('/');
    }
  }

  void _mostrarSelectorColor(BuildContext context) {
    final config = context.read<ProveedorConfig>();
    const colores = [
      Color(0xFF00BFA5), Color(0xFF007AFF), Color(0xFF5856D6),
      Color(0xFFFF2D55), Color(0xFFFF9500), Color(0xFF34C759),
      Color(0xFFFF3B30), Color(0xFF4ECDC4), Color(0xFF1ABC9C),
      Color(0xFF8E44AD), Color(0xFF2ECC71), Color(0xFFE74C3C),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kTextMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color de la aplicación',
                style: TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colores.map((c) {
                final seleccionado = config.colorPrimario.value == c.value;
                return GestureDetector(
                  onTap: () {
                    config.actualizarColor(c);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: seleccionado
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: seleccionado
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _OpcionConfig(
            icono: Icons.design_services_outlined,
            titulo: 'Servicios',
            subtitulo: 'Gestionar servicios del negocio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaGestionServicios()),
            ),
          ),
          const SizedBox(height: 12),
          _OpcionConfig(
            icono: Icons.people_outline,
            titulo: 'Perfiles',
            subtitulo: 'Empleados y clientes registrados',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaGestionEmpleados()),
            ),
          ),
          const SizedBox(height: 12),
          _OpcionConfig(
            icono: Icons.inventory_2_outlined,
            titulo: 'Inventario',
            subtitulo: 'Agregar, editar y eliminar productos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaInventario()),
            ),
          ),
          const SizedBox(height: 12),
          _OpcionConfig(
            icono: Icons.storefront_outlined,
            titulo: 'Inspeccionar Tienda',
            subtitulo: 'Ver la tienda como la ven los clientes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaProductos()),
            ),
          ),
          const SizedBox(height: 12),
          _OpcionConfig(
            icono: Icons.palette_outlined,
            titulo: 'Color de la aplicación',
            subtitulo: 'Cambia el color principal de la app',
            onTap: () => _mostrarSelectorColor(context),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _salir(context),
            icon: const Icon(Icons.logout, color: Color(0xFF6E6E73)),
            label: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFF6E6E73))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kDivider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionConfig extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _OpcionConfig({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kNeumorphicShadowsSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorPrimario.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: context.colorPrimario, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitulo,
                      style: const TextStyle(color: kTextMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextMuted),
          ],
        ),
      ),
    );
  }
}
