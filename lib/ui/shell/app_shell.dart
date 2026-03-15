import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../../domain/enums/user_role.dart';
import '../../core/theme/app_theme.dart';

// Cliente
import '../client/home_page.dart';
import '../client/my_bookings_page.dart';
import '../client/profile_page.dart';

// Empleado
import '../employee/employee_dashboard_page.dart';
import '../employee/employee_bookings_page.dart';

// Admin
import '../admin/admin_dashboard_page.dart';
import '../admin/all_bookings_page.dart';
import '../admin/manage_employees_page.dart';
import '../admin/admin_orders_page.dart';
import '../admin/admin_settings_page.dart';
import '../admin/insumos_page.dart';

// Sysadmin
import '../sysadmin/sysadmin_dashboard_page.dart';
import '../sysadmin/sysadmin_logs_page.dart';
import '../sysadmin/sysadmin_config_page.dart';
import '../../data/activity_service.dart';

// Carrito & Guardados
import '../cart/cart_page.dart';
import '../saved/saved_page.dart';
import '../auth/guest_wall_page.dart';

class CarcasaApp extends StatefulWidget {
  const CarcasaApp({super.key});

  @override
  State<CarcasaApp> createState() => _CarcasaAppState();
}

class _CarcasaAppState extends State<CarcasaApp> {
  int _indiceActual = 0;
  final _keyDashboardAdmin = GlobalKey<PaginaTableroAdminState>();
  final _keyConfigSysadmin = GlobalKey<PaginaConfigSysadminState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = context.read<ProveedorAuth>().perfil;
      if (perfil != null) {
        context.read<ProveedorGuardados>().cargar(perfil.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProveedorAuth>();

    // Esperando restaurar sesión
    if (auth.inicializando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final perfil = auth.perfil;

    // Modo invitado: mostrar tienda sin login
    if (perfil == null) {
      return _ShellInvitado(
        indiceActual: _indiceActual,
        onTap: (i) => setState(() => _indiceActual = i),
      );
    }

    final pestanas = _pestanasPorRol(perfil.rol);
    final indiceSafe = _indiceActual.clamp(0, pestanas.length - 1);
    final esAdmin =
        perfil.rol == RolUsuario.admin || perfil.rol == RolUsuario.superAdmin;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: indiceSafe,
        children: pestanas.map((t) => t.pagina).toList(),
      ),
      bottomNavigationBar: _BarraNavegacion(
        pestanas: pestanas,
        indiceSafe: indiceSafe,
        mostrarCarrito: false,
        onTap: (i) {
          setState(() => _indiceActual = i);
          _refrescarAlCambiarTab(i, perfil.rol);
        },
      ),
    );
  }

  void _refrescarAlCambiarTab(int indice, RolUsuario rol) {
    final perfil = context.read<ProveedorAuth>().perfil;
    if (perfil == null) return;
    final reserva = context.read<ProveedorReserva>();
    final tabs = _pestanasPorRol(rol);
    if (indice < tabs.length) {
      ServicioActividad.instancia.registrarPantalla(tabs[indice].etiqueta);
    }

    switch (rol) {
      case RolUsuario.sysadmin:
        if (indice == 2) _keyConfigSysadmin.currentState?.recargar();
        break;
      case RolUsuario.client:
        if (indice == 1) reserva.cargarReservasCliente(perfil.id);
        break;
      case RolUsuario.employee:
        if (indice == 1) reserva.cargarReservasEmpleado(perfil.id);
        break;
      case RolUsuario.admin:
      case RolUsuario.superAdmin:
        if (indice == 0) _keyDashboardAdmin.currentState?.recargar();
        if (indice == 1) reserva.cargarTodasLasReservas();
        break;
    }
  }

  List<_Pestana> _pestanasPorRol(RolUsuario role) {
    switch (role) {
      case RolUsuario.sysadmin:
        return [
          _Pestana(Icons.shield_outlined, 'Dashboard',
              const PaginaTableroSysadmin(),
              imagen: 'IMG/ADMIN.png'),
          _Pestana(Icons.analytics_outlined, 'Logs', const PaginaLogs(),
              imagen: 'IMG/ESTADISTICAS.png'),
          _Pestana(Icons.manage_accounts_outlined, 'Config',
              PaginaConfigSysadmin(key: _keyConfigSysadmin),
              imagen: 'IMG/PERFILESC.png'),
        ];
      case RolUsuario.superAdmin:
      case RolUsuario.admin:
        return [
          _Pestana(Icons.dashboard_outlined, 'Dashboard',
              PaginaTableroAdmin(key: _keyDashboardAdmin),
              imagen: 'IMG/DASHBOARD.png'),
          _Pestana(Icons.calendar_today_outlined, 'Reservas',
              const PaginaTodasReservas(),
              imagen: 'IMG/RESERVAS.png'),
          _Pestana(Icons.receipt_long_outlined, 'Pedidos',
              const PaginaPedidosAdmin(),
              imagen: 'IMG/PEDIDOS.png'),
          _Pestana(Icons.inventory_2_outlined, 'Insumos', const PaginaInsumos(),
              imagen: 'IMG/INSUMOS.png'),
          _Pestana(Icons.settings_outlined, 'Config', const PaginaConfigAdmin(),
              imagen: 'IMG/CONFIGURACION.png'),
        ];
      case RolUsuario.employee:
        return [
          _Pestana(Icons.dashboard_outlined, 'Mi Panel',
              const PaginaTableroEmpleado(),
              imagen: 'IMG/INICIO.png'),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
              const PaginaReservasEmpleado(),
              imagen: 'IMG/RESERVAS.png'),
          _Pestana(
              Icons.shopping_cart_outlined, 'Carrito', const PaginaCarrito(),
              imagen: 'IMG/CARRITO_NAV.png'),
          _Pestana(Icons.favorite_border_rounded, 'Favoritos',
              const PaginaGuardados(),
              imagen: 'IMG/FAVORITOS.png'),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil(),
              imagen: 'IMG/PERFIL.png'),
        ];
      case RolUsuario.client:
        return [
          _Pestana(Icons.home_outlined, 'Inicio', const PaginaInicio(),
              imagen: 'IMG/INICIO.png'),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
              const PaginaMisReservas(),
              imagen: 'IMG/RESERVAS.png'),
          _Pestana(
              Icons.shopping_cart_outlined, 'Carrito', const PaginaCarrito(),
              imagen: 'IMG/CARRITO_NAV.png'),
          _Pestana(Icons.favorite_border_rounded, 'Favoritos',
              const PaginaGuardados(),
              imagen: 'IMG/FAVORITOS.png'),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil(),
              imagen: 'IMG/PERFIL.png'),
        ];
    }
  }
}

// ── Barra de navegación con carrito flotante ─────────────────
class _BarraNavegacion extends StatelessWidget {
  final List<_Pestana> pestanas;
  final int indiceSafe;
  final bool mostrarCarrito;
  final ValueChanged<int> onTap;

  const _BarraNavegacion({
    required this.pestanas,
    required this.indiceSafe,
    required this.mostrarCarrito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Ancho disponible descontando padding lateral (20+20) y espacio entre tabs
    final itemWidth = (screenWidth - 40) / pestanas.length;
    // Ícono máximo 52px pero nunca más del 70% del espacio de cada tab
    final iconSize = (itemWidth * 0.70).clamp(28.0, 52.0);
    final barHeight = (iconSize + 44).clamp(72.0, 96.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x22FFFFFF),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(pestanas.length, (i) {
            final selected = i == indiceSafe;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: EdgeInsets.zero,
                decoration: selected
                    ? BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      )
                    : null,
                child: pestanas[i].imagen != null
                    ? Image.asset(
                        pestanas[i].imagen!,
                        width: iconSize,
                        height: iconSize,
                      )
                    : Icon(
                        selected
                            ? _iconoActivo(pestanas[i].icono)
                            : pestanas[i].icono,
                        color: selected ? kPrimary : const Color(0xFF6E6E73),
                        size: iconSize * 0.85,
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

IconData _iconoActivo(IconData icono) {
  if (icono == Icons.home_outlined) return Icons.home;
  if (icono == Icons.calendar_today_outlined) return Icons.calendar_today;
  if (icono == Icons.shopping_bag_outlined) return Icons.shopping_bag;
  if (icono == Icons.favorite_border_rounded) return Icons.favorite_rounded;
  if (icono == Icons.person_outline) return Icons.person;
  if (icono == Icons.dashboard_outlined) return Icons.dashboard;
  if (icono == Icons.people_outline) return Icons.people;
  if (icono == Icons.receipt_long_outlined) return Icons.receipt_long;
  return icono;
}

class _Pestana {
  final IconData icono;
  final String? imagen; // ruta asset PNG personalizado
  final String etiqueta;
  final Widget pagina;
  const _Pestana(this.icono, this.etiqueta, this.pagina, {this.imagen});
}

// ── Shell para invitados (sin login) ─────────────────────────
class _ShellInvitado extends StatelessWidget {
  final int indiceActual;
  final ValueChanged<int> onTap;

  const _ShellInvitado({required this.indiceActual, required this.onTap});

  static const _pestanas = [
    _Pestana(Icons.home_outlined, 'Inicio', PaginaInicio(),
        imagen: 'IMG/INICIO.png'),
    _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tus reservas'),
        imagen: 'IMG/RESERVAS.png'),
    _Pestana(Icons.favorite_border_rounded, 'Favoritos',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tus favoritos'),
        imagen: 'IMG/FAVORITOS.png'),
    _Pestana(Icons.person_outline, 'Perfil',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tu perfil'),
        imagen: 'IMG/PERFIL.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final indice = indiceActual.clamp(0, _pestanas.length - 1);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: indice,
        children: _pestanas.map((t) => t.pagina).toList(),
      ),
      bottomNavigationBar: _BarraNavegacion(
        pestanas: _pestanas,
        indiceSafe: indice,
        mostrarCarrito: true,
        onTap: onTap,
      ),
    );
  }
}
