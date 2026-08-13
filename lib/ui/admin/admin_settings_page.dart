import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import 'manage_services_page.dart';
import 'manage_employees_page.dart';
import 'manage_products_page.dart';
import 'commission_config_page.dart';
import '../products/products_page.dart';

class PaginaConfigAdmin extends StatelessWidget {
  const PaginaConfigAdmin({super.key});

  Future<void> _salir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: const Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(color: Color(0xFF1C1C1E))),
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

  @override
  Widget build(BuildContext context) {
    final tiendaHabilitada = context.watch<ProveedorConfig>().tiendaHabilitada;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(),
      body: EnvolturaResponsiva(
        child: ListView(
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
          if (tiendaHabilitada) ...[
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
          ],
          const SizedBox(height: 12),
          _OpcionConfig(
            icono: Icons.percent_rounded,
            titulo: 'Comisiones',
            subtitulo: 'Configurar comisiones por servicio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaConfigComisiones()),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _salir(context),
            icon: const Icon(Icons.logout, color: Color(0xFF6E6E73)),
            label: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFF6E6E73))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E5EA)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
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
          color: Colors.white,
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
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14)),
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
