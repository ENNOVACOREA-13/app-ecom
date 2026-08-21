import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/saved_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/notification_provider.dart';
import '../../domain/enums/user_role.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_page.dart';

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
import '../admin/admin_orders_page.dart';
import '../admin/admin_settings_page.dart';
import '../admin/insumos_page.dart';

// Sysadmin
import '../sysadmin/sysadmin_dashboard_page.dart';
import '../sysadmin/sysadmin_logs_page.dart';
import '../sysadmin/sysadmin_config_page.dart';
import '../sysadmin/view_designer_page.dart';
import '../platform_admin/tenants_page.dart';
import '../../data/activity_service.dart';

// Guardados
import '../saved/saved_page.dart';
import '../auth/guest_wall_page.dart';

// Envuelve el contenido de cada pestaña con márgenes laterales en
// escritorio; en móvil lo deja tal cual.
Widget _contenidoResponsivo(BuildContext context, Widget child) {
  final anchoPantalla = MediaQuery.of(context).size.width;
  if (anchoPantalla < kAnchoEscritorio) return child;
  final margen = margenLateralEscritorio(anchoPantalla);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: margen),
    child: child,
  );
}

class CarcasaApp extends StatefulWidget {
  const CarcasaApp({super.key});

  @override
  State<CarcasaApp> createState() => _CarcasaAppState();
}

class _CarcasaAppState extends State<CarcasaApp> with SingleTickerProviderStateMixin {
  int _indiceActual = 0;
  final _keyDashboardAdmin = GlobalKey<PaginaTableroAdminState>();
  final _keyDashboardEmpleado = GlobalKey<PaginaTableroEmpleadoState>();
  final _keyConfigSysadmin = GlobalKey<PaginaConfigSysadminState>();
  late final AnimationController _fadeController;
  String? _perfilIniciadoId;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
  }

  // Se llama desde build() en cada rebuild (no solo initState): el perfil
  // suele seguir cargando (async) en el primer frame, así que un solo intento
  // en initState se lo perdía casi siempre — favoritos y notificaciones
  // nunca se inicializaban en una sesión ya iniciada al abrir la app.
  // iniciar()/cargar() ya son idempotentes por id, así que es seguro llamarlos
  // de más; solo hace falta disparar el efecto una vez que el perfil cambia.
  void _iniciarProveedoresDependientesDePerfil(String? perfilId) {
    if (perfilId == null || perfilId == _perfilIniciadoId) return;
    _perfilIniciadoId = perfilId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProveedorGuardados>().cargar(perfilId);
      context.read<ProveedorNotificaciones>().iniciar(perfilId);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _cambiarTab(int indice) {
    setState(() => _indiceActual = indice);
    _fadeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProveedorAuth>();
    final tiendaHabilitada = context.watch<ProveedorConfig>().tiendaHabilitada;
    final editorVistasAdmin = context.watch<ProveedorConfig>().editorVistasAdmin;
    final reservasHabilitadas = context.watch<ProveedorConfig>().reservasHabilitadas;

    // Esperando restaurar sesión
    if (auth.inicializando) {
      return Scaffold(
        backgroundColor: kBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final perfil = auth.perfil;
    _iniciarProveedoresDependientesDePerfil(perfil?.id);

    // ProveedorAuth ya garantiza que un perfil no-nulo es válido para ESTE
    // dominio (o platform_admin) — ver _validarTenant() en auth_provider.dart
    // y el guard equivalente en RepositorioAuth.iniciarSesion(). Una cuenta
    // real de otro negocio nunca llega a construirse como perfil aquí; se
    // cierra su sesión en silencio antes, sin ningún mensaje distinto a "no
    // hay sesión" — mostrar algo como "esta cuenta no tiene acceso aquí"
    // confirmaría que el correo/contraseña sí son válidos en otro negocio.
    if (perfil == null && kTenantIdActivo == null) {
      // Dominio sin tenant (ej. el control plane, app-mc.vercel.app): solo
      // platform_admin tiene algo que hacer aquí, así que un invitado ve
      // nada más que el login, nunca una tienda de invitado.
      return const PaginaLogin();
    }

    // Modo invitado: mostrar tienda sin login
    if (perfil == null) {
      return _ShellInvitado(
        indiceActual: _indiceActual,
        tiendaHabilitada: tiendaHabilitada,
        reservasHabilitadas: reservasHabilitadas,
        fadeController: _fadeController,
        onTap: _cambiarTab,
      );
    }

    // platform_admin es la única cuenta con algo que hacer en el control
    // plane, y tiene una sola pantalla — el sidebar blanco compartido con
    // el resto de los roles no aporta nada aquí (nada entre qué navegar) y
    // rompería el tema negro deliberadamente distinto de ese panel. Se
    // renderiza directo, sin el chrome del shell normal.
    if (perfil.rol == RolUsuario.platformAdmin) {
      return const PaginaNegocios();
    }

    final pestanas = _pestanasPorRol(
        perfil.rol, tiendaHabilitada, editorVistasAdmin, reservasHabilitadas);
    final indiceSafe = _indiceActual.clamp(0, pestanas.length - 1);
    final esEscritorio = MediaQuery.of(context).size.width >= kAnchoEscritorio;

    void alSeleccionar(int i) {
      _cambiarTab(i);
      _refrescarAlCambiarTab(i, perfil.rol);
    }

    final contenido = _contenidoResponsivo(
      context,
      FadeTransition(
        opacity: _fadeController,
        child: IndexedStack(
          index: indiceSafe,
          children: pestanas.map((t) => t.pagina).toList(),
        ),
      ),
    );

    return Scaffold(
      extendBody: true,
      body: esEscritorio
          ? _MenuHamburguesaEscritorio(
              pestanas: pestanas,
              indiceSafe: indiceSafe,
              onTap: alSeleccionar,
              child: contenido,
            )
          : contenido,
      bottomNavigationBar: esEscritorio || pestanas.length <= 1
          ? null
          : _BarraNavegacion(
              pestanas: pestanas,
              indiceSafe: indiceSafe,
              mostrarCarrito: false,
              onTap: alSeleccionar,
            ),
    );
  }

  void _refrescarAlCambiarTab(int indice, RolUsuario rol) {
    final perfil = context.read<ProveedorAuth>().perfil;
    if (perfil == null) return;
    final reserva = context.read<ProveedorReserva>();
    final cfg = context.read<ProveedorConfig>();
    final tabs = _pestanasPorRol(
        rol, cfg.tiendaHabilitada, cfg.editorVistasAdmin, cfg.reservasHabilitadas);
    if (indice >= tabs.length) return;
    final id = tabs[indice].id;
    ServicioActividad.instancia.registrarPantalla(tabs[indice].etiqueta);

    switch (id) {
      case 'sysadmin_config':
        _keyConfigSysadmin.currentState?.recargar();
        break;
      case 'client_reservas':
        reserva.cargarReservasCliente(perfil.id);
        break;
      case 'employee_reservas':
        reserva.cargarReservasEmpleado(perfil.id);
        break;
      case 'employee_dashboard':
        _keyDashboardEmpleado.currentState?.recargar();
        break;
      case 'admin_dashboard':
        _keyDashboardAdmin.currentState?.recargar();
        break;
      case 'admin_reservas':
        reserva.cargarTodasLasReservas();
        break;
    }
  }

  List<_Pestana> _pestanasPorRol(RolUsuario role, bool tiendaHabilitada,
      bool editorVistasAdmin, bool reservasHabilitadas) {
    switch (role) {
      case RolUsuario.platformAdmin:
        return [
          _Pestana(Icons.apartment_outlined, 'Negocios',
              const PaginaNegocios(),
              imagen: 'IMG/ADMIN.png', id: 'platform_admin_negocios'),
        ];
      case RolUsuario.sysadmin:
        return [
          _Pestana(Icons.shield_outlined, 'Dashboard',
              const PaginaTableroSysadmin(),
              imagen: 'IMG/ADMIN.png', id: 'sysadmin_dashboard'),
          _Pestana(Icons.analytics_outlined, 'Logs', const PaginaLogs(),
              imagen: 'IMG/ESTADISTICAS.png', id: 'sysadmin_logs'),
          _Pestana(Icons.manage_accounts_outlined, 'Config',
              PaginaConfigSysadmin(key: _keyConfigSysadmin),
              imagen: 'IMG/PERFILESC.png', id: 'sysadmin_config'),
          _Pestana(Icons.dashboard_customize_outlined, 'Vista',
              const PaginaDisenadorVista(),
              imagen: 'IMG/CONFIGURACION.png', id: 'sysadmin_vista'),
        ];
      case RolUsuario.superAdmin:
      case RolUsuario.admin:
        return [
          _Pestana(Icons.dashboard_outlined, 'Dashboard',
              PaginaTableroAdmin(key: _keyDashboardAdmin),
              imagen: 'IMG/DASHBOARD.png', id: 'admin_dashboard'),
          if (reservasHabilitadas)
            _Pestana(Icons.calendar_today_outlined, 'Reservas',
                const PaginaTodasReservas(),
                imagen: 'IMG/RESERVAS.png', id: 'admin_reservas'),
          if (tiendaHabilitada)
            _Pestana(Icons.receipt_long_outlined, 'Pedidos',
                const PaginaPedidosAdmin(),
                imagen: 'IMG/PEDIDOS.png', id: 'admin_pedidos'),
          _Pestana(Icons.inventory_2_outlined, 'Insumos', const PaginaInsumos(),
              imagen: 'IMG/INSUMOS.png', id: 'admin_insumos'),
          if (editorVistasAdmin)
            _Pestana(Icons.dashboard_customize_outlined, 'Vista',
                const PaginaDisenadorVista(),
                imagen: 'IMG/CONFIGURACION.png', id: 'admin_vista'),
          _Pestana(Icons.settings_outlined, 'Config', const PaginaConfigAdmin(),
              imagen: 'IMG/CONFIGURACION.png', id: 'admin_config'),
        ];
      case RolUsuario.employee:
        return [
          _Pestana(Icons.dashboard_outlined, 'Mi Panel',
              PaginaTableroEmpleado(key: _keyDashboardEmpleado),
              imagen: 'IMG/INICIO.png', id: 'employee_dashboard'),
          if (reservasHabilitadas)
            _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
                const PaginaReservasEmpleado(),
                imagen: 'IMG/RESERVAS.png', id: 'employee_reservas'),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil(),
              imagen: 'IMG/PERFIL.png', id: 'employee_perfil'),
        ];
      case RolUsuario.client:
        return [
          _Pestana(Icons.home_outlined, 'Inicio', const PaginaInicio(),
              imagen: 'IMG/INICIO.png', id: 'client_inicio'),
          if (reservasHabilitadas)
            _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
                const PaginaMisReservas(),
                imagen: 'IMG/RESERVAS.png', id: 'client_reservas'),
          if (tiendaHabilitada)
            _Pestana(Icons.favorite_border_rounded, 'Favoritos',
                const PaginaGuardados(),
                imagen: 'IMG/FAVORITOS.png', id: 'client_favoritos'),
          _Pestana(Icons.person_outline, 'Perfil', const PaginaPerfil(),
              imagen: 'IMG/PERFIL.png', id: 'client_perfil'),
        ];
    }
  }
}

// ── Barra de navegación con carrito flotante ─────────────────
// Curvas propias (las de Flutter por defecto se sienten débiles) — misma
// idea que --ease-out/--ease-in-out de la skill de Emil Kowalski.
const _kEaseOutFuerte = Cubic(0.23, 1, 0.32, 1);
const _kEaseInOutFuerte = Cubic(0.77, 0, 0.175, 1);

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
    final itemWidth = screenWidth / pestanas.length;
    final iconSize = (itemWidth * 0.70).clamp(22.0, 38.0);
    final barHeight = (iconSize + 44).clamp(64.0, 84.0);
    final indicadorTamano = iconSize + 12;

    return Container(
      height: barHeight,
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.zero,
        boxShadow: [
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
      child: Stack(
        children: [
          // El indicador es UN solo círculo que se desliza de pestaña en
          // pestaña — antes cada ícono aparecía/desaparecía por su cuenta
          // en su propio lugar, sin ningún movimiento que conectara una
          // selección con la siguiente, así que el cambio se sentía
          // "cortado" en vez de fluido.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: _kEaseInOutFuerte,
            left: indiceSafe * itemWidth + (itemWidth - indicadorTamano) / 2,
            top: (barHeight - indicadorTamano) / 2,
            width: indicadorTamano,
            height: indicadorTamano,
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          Row(
            children: List.generate(pestanas.length, (i) {
              final selected = i == indiceSafe;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: _kEaseOutFuerte,
                      scale: selected ? 1.05 : 1.0,
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(
                          begin: Colors.white,
                          end: selected ? Colors.black : Colors.white,
                        ),
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.ease,
                        builder: (context, color, child) => Icon(
                          selected
                              ? _iconoActivo(pestanas[i].icono)
                              : pestanas[i].icono,
                          color: color,
                          size: iconSize * 0.85,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
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
  final String? imagen; // ruta asset PNG personalizado
  final String etiqueta;
  final Widget pagina;
  final String id;
  const _Pestana(this.icono, this.etiqueta, this.pagina,
      {this.imagen, this.id = ''});
}

// ── Shell para invitados (sin login) ─────────────────────────
class _ShellInvitado extends StatelessWidget {
  final int indiceActual;
  final bool tiendaHabilitada;
  final bool reservasHabilitadas;
  final AnimationController fadeController;
  final ValueChanged<int> onTap;

  const _ShellInvitado({
    required this.indiceActual,
    required this.tiendaHabilitada,
    required this.reservasHabilitadas,
    required this.fadeController,
    required this.onTap,
  });

  static const _pestanasBase = [
    _Pestana(Icons.home_outlined, 'Inicio', PaginaInicio(),
        imagen: 'IMG/INICIO.png'),
  ];

  static const _pestanasReservas = [
    _Pestana(Icons.calendar_today_outlined, 'Mis Reservas',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tus reservas'),
        imagen: 'IMG/RESERVAS.png'),
  ];

  static const _pestanasTienda = [
    _Pestana(Icons.favorite_border_rounded, 'Favoritos',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tus favoritos'),
        imagen: 'IMG/FAVORITOS.png'),
  ];

  static const _pestanasFinal = [
    _Pestana(Icons.person_outline, 'Perfil',
        PaginaMuroInvitado(mensaje: 'Inicia sesión para ver tu perfil'),
        imagen: 'IMG/PERFIL.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final pestanas = [
      ..._pestanasBase,
      if (reservasHabilitadas) ..._pestanasReservas,
      if (tiendaHabilitada) ..._pestanasTienda,
      ..._pestanasFinal,
    ];
    final indice = indiceActual.clamp(0, pestanas.length - 1);
    final esEscritorio = MediaQuery.of(context).size.width >= kAnchoEscritorio;
    final contenido = _contenidoResponsivo(
      context,
      FadeTransition(
        opacity: fadeController,
        child: IndexedStack(
          index: indice,
          children: pestanas.map((t) => t.pagina).toList(),
        ),
      ),
    );
    return Scaffold(
      extendBody: true,
      body: esEscritorio
          ? _MenuHamburguesaEscritorio(
              pestanas: pestanas,
              indiceSafe: indice,
              onTap: onTap,
              child: contenido,
            )
          : contenido,
      bottomNavigationBar: esEscritorio
          ? null
          : _BarraNavegacion(
              pestanas: pestanas,
              indiceSafe: indice,
              mostrarCarrito: true,
              onTap: onTap,
            ),
    );
  }
}

// ── Menú de hamburguesa para escritorio (se desliza de arriba) ───
// Reserva su propia barra fija (no flota sobre el contenido de cada
// página), así el botón nunca queda tapando el encabezado de nadie.
// ── Barra lateral fija de escritorio (tipo ChatGPT) ───────────────
// Se puede colapsar a una franja angosta solo con íconos, o expandir
// para ver también las etiquetas. Empuja el contenido en vez de
// flotar encima de él.
class _MenuHamburguesaEscritorio extends StatefulWidget {
  final List<_Pestana> pestanas;
  final int indiceSafe;
  final ValueChanged<int> onTap;
  final Widget child;

  const _MenuHamburguesaEscritorio({
    required this.pestanas,
    required this.indiceSafe,
    required this.onTap,
    required this.child,
  });

  @override
  State<_MenuHamburguesaEscritorio> createState() =>
      _MenuHamburguesaEscritorioState();
}

class _MenuHamburguesaEscritorioState
    extends State<_MenuHamburguesaEscritorio> {
  bool _abierta = true;

  void _alternar() => setState(() => _abierta = !_abierta);

  static const _anchoAbierta = 232.0;
  static const _anchoCerrada = 72.0;

  @override
  Widget build(BuildContext context) {
    final ancho = _abierta ? _anchoAbierta : _anchoCerrada;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: ancho,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE5E5EA))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  alignment:
                      _abierta ? Alignment.centerRight : Alignment.center,
                  child: GestureDetector(
                    onTap: _alternar,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          _abierta
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          size: 19,
                          color: const Color(0xFF1C1C1E)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: widget.pestanas.length,
                  itemBuilder: (context, i) {
                    final seleccionado = i == widget.indiceSafe;
                    final p = widget.pestanas[i];
                    final textoColor = seleccionado
                        ? context.colorPrimario
                        : const Color(0xFF6E6E73);
                    // Mismo lenguaje visual que el resto de la app: ícono
                    // dentro de un círculo (categorías, opciones de config,
                    // notificaciones), no un simple ícono suelto.
                    final icono = Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? context.colorPrimario
                            : const Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          seleccionado ? _iconoActivo(p.icono) : p.icono,
                          color: seleccionado
                              ? Colors.white
                              : const Color(0xFF6E6E73),
                          size: 18),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: seleccionado
                            ? context.colorPrimario.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => widget.onTap(i),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: _abierta ? 8 : 0, vertical: 8),
                            child: _abierta
                                ? Row(
                                    children: [
                                      icono,
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(p.etiqueta,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: textoColor,
                                                fontSize: 13,
                                                fontWeight: seleccionado
                                                    ? FontWeight.w700
                                                    : FontWeight.w500)),
                                      ),
                                    ],
                                  )
                                : Center(child: icono),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
