import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../domain/enums/user_role.dart';
import '../../core/theme/app_theme.dart';

// Cliente
import '../client/home_page.dart';
import '../client/my_bookings_page.dart';
import '../products/products_page.dart';
import '../client/profile_page.dart';

// Empleado
import '../employee/employee_dashboard_page.dart';
import '../employee/employee_bookings_page.dart';

// Admin
import '../admin/admin_dashboard_page.dart';
import '../admin/all_bookings_page.dart';
import '../admin/manage_services_page.dart';
import '../admin/manage_employees_page.dart';

class CarcasaApp extends StatefulWidget {
  const CarcasaApp({super.key});

  @override
  State<CarcasaApp> createState() => _CarcasaAppState();
}

class _CarcasaAppState extends State<CarcasaApp> {
  int _indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    if (perfil == null) return const SizedBox.shrink();

    final pestanas = _pestanasPorRol(perfil.rol);

    // Clamp index en caso de que cambió el rol
    final indiceSafe = _indiceActual.clamp(0, pestanas.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: indiceSafe,
        children: pestanas.map((t) => t.pagina).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(pestanas.length, (i) {
              final selected = i == indiceSafe;
              return GestureDetector(
                onTap: () {
                  setState(() => _indiceActual = i);
                  _refrescarAlCambiarTab(i, perfil.rol);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? kPrimary.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? _iconoActivo(pestanas[i].icono) : pestanas[i].icono,
                    color: selected ? kPrimary : const Color(0xFF6E6E73),
                    size: 24,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _refrescarAlCambiarTab(int indice, RolUsuario rol) {
    final perfil = context.read<ProveedorAuth>().perfil;
    if (perfil == null) return;
    final reserva = context.read<ProveedorReserva>();

    switch (rol) {
      case RolUsuario.client:
        if (indice == 1) reserva.cargarReservasCliente(perfil.id);
        break;
      case RolUsuario.employee:
        if (indice == 1) reserva.cargarReservasEmpleado(perfil.id);
        break;
      case RolUsuario.admin:
      case RolUsuario.superAdmin:
        if (indice == 1) reserva.cargarTodasLasReservas();
        break;
    }
  }

  List<_Pestana> _pestanasPorRol(RolUsuario role) {
    switch (role) {
      case RolUsuario.superAdmin:
      case RolUsuario.admin:
        return [
          _Pestana(Icons.dashboard_outlined, 'Dashboard', const PaginaTableroAdmin()),
          _Pestana(Icons.calendar_today_outlined, 'Reservas', const PaginaTodasReservas()),
          _Pestana(Icons.design_services_outlined, 'Servicios', const PaginaGestionServicios()),
          _Pestana(Icons.people_outline, 'Empleados', const PaginaGestionEmpleados()),
          _Pestana(Icons.shopping_bag_outlined, 'Tienda', const PaginaProductos()),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil()),
        ];
      case RolUsuario.employee:
        return [
          _Pestana(Icons.dashboard_outlined, 'Mi Panel', const PaginaTableroEmpleado()),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas', const PaginaReservasEmpleado()),
          _Pestana(Icons.shopping_bag_outlined, 'Tienda', const PaginaProductos()),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil()),
        ];
      case RolUsuario.client:
        return [
          _Pestana(Icons.home_outlined, 'Inicio', const PaginaInicio()),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas', const PaginaMisReservas()),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil()),
        ];
    }
  }
}

IconData _iconoActivo(IconData icono) {
  if (icono == Icons.home_outlined) return Icons.home;
  if (icono == Icons.calendar_today_outlined) return Icons.calendar_today;
  if (icono == Icons.shopping_bag_outlined) return Icons.shopping_bag;
  if (icono == Icons.person_outline) return Icons.person;
  if (icono == Icons.dashboard_outlined) return Icons.dashboard;
  if (icono == Icons.design_services_outlined) return Icons.design_services;
  if (icono == Icons.people_outline) return Icons.people;
  return icono;
}

class _Pestana {
  final IconData icono;
  final String etiqueta;
  final Widget pagina;
  const _Pestana(this.icono, this.etiqueta, this.pagina);
}
