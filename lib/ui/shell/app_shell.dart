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

// Carrito & Guardados
import '../cart/cart_page.dart';
import '../saved/saved_page.dart';

class CarcasaApp extends StatefulWidget {
  const CarcasaApp({super.key});

  @override
  State<CarcasaApp> createState() => _CarcasaAppState();
}

class _CarcasaAppState extends State<CarcasaApp> {
  int _indiceActual = 0;
  final _keyDashboardAdmin = GlobalKey<PaginaTableroAdminState>();

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
    final perfil = context.watch<ProveedorAuth>().perfil;
    if (perfil == null) return const SizedBox.shrink();

    final pestanas = _pestanasPorRol(perfil.rol);
    final indiceSafe = _indiceActual.clamp(0, pestanas.length - 1);
    final esAdmin = perfil.rol == RolUsuario.admin || perfil.rol == RolUsuario.superAdmin;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: indiceSafe,
        children: pestanas.map((t) => t.pagina).toList(),
      ),
      bottomNavigationBar: _BarraNavegacion(
        pestanas: pestanas,
        indiceSafe: indiceSafe,
        mostrarCarrito: !esAdmin,
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

    switch (rol) {
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
      case RolUsuario.superAdmin:
      case RolUsuario.admin:
        return [
          _Pestana(Icons.dashboard_outlined, 'Dashboard', PaginaTableroAdmin(key: _keyDashboardAdmin)),
          _Pestana(Icons.calendar_today_outlined, 'Reservas', const PaginaTodasReservas()),
          _Pestana(Icons.receipt_long_outlined, 'Pedidos', const PaginaPedidosAdmin()),
          _Pestana(Icons.settings_outlined, 'Config', const PaginaConfigAdmin()),
        ];
      case RolUsuario.employee:
        return [
          _Pestana(Icons.dashboard_outlined, 'Mi Panel', const PaginaTableroEmpleado()),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas', const PaginaReservasEmpleado()),
          _Pestana(Icons.favorite_border_rounded, 'Favoritos', const PaginaGuardados()),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil()),
        ];
      case RolUsuario.client:
        return [
          _Pestana(Icons.home_outlined, 'Inicio', const PaginaInicio()),
          _Pestana(Icons.calendar_today_outlined, 'Mis Reservas', const PaginaMisReservas()),
          _Pestana(Icons.favorite_border_rounded, 'Favoritos', const PaginaGuardados()),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil()),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Nav bar
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(pestanas.length, (i) {
                final selected = i == indiceSafe;
                return GestureDetector(
                  onTap: () => onTap(i),
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

          // Carrito flotante (solo para client y employee)
          if (mostrarCarrito)
            Positioned(
              top: -26,
              child: Consumer<ProveedorCarrito>(
                builder: (ctx, carrito, _) => GestureDetector(
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute(builder: (_) => const PaginaCarrito()),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      if (carrito.totalItems > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                carrito.totalItems > 99 ? '99+' : '${carrito.totalItems}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
  final String etiqueta;
  final Widget pagina;
  const _Pestana(this.icono, this.etiqueta, this.pagina);
}
