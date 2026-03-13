import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/booking_repository.dart';
import '../../data/order_repository.dart';
import '../../domain/models/order.dart';
import '../../domain/enums/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';
import '../admin/manage_services_page.dart';
import '../admin/manage_employees_page.dart';
import '../admin/manage_products_page.dart';
import '../admin/commission_config_page.dart';
import '../products/products_page.dart';
import '../client/profile_page.dart';

class PaginaTableroAdmin extends StatefulWidget {
  const PaginaTableroAdmin({super.key});

  @override
  State<PaginaTableroAdmin> createState() => PaginaTableroAdminState();
}

class PaginaTableroAdminState extends State<PaginaTableroAdmin> {
  final _repoReserva = RepositorioReserva();
  final _repoPedido = RepositorioPedido();

  List<Map<String, dynamic>> _estEmpleados = [];
  List<Map<String, dynamic>> _serviciosPopulares = [];
  List<Pedido> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> recargar() => _cargar();

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        _repoReserva.obtenerTodasEstadisticasEmpleados(),
        _repoReserva.obtenerServiciosPopulares(),
        _repoPedido.obtenerTodosPedidos(),
      ]);
      setState(() {
        _estEmpleados = resultados[0] as List<Map<String, dynamic>>;
        _serviciosPopulares = resultados[1] as List<Map<String, dynamic>>;
        _pedidos = resultados[2] as List<Pedido>;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  static const _coloresPreset = [
    Color(0xFF4ECDC4), Color(0xFF7C3AED), Color(0xFF007AFF), Color(0xFF34C759),
    Color(0xFFFF9500), Color(0xFFFF2D55), Color(0xFF5856D6), Color(0xFF1ABC9C),
    Color(0xFFFF6B6B), Color(0xFFE91E63), Color(0xFF2196F3), Color(0xFFFF5722),
  ];

  void _mostrarConfiguracion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              const Text('Configuración',
                  style: TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _OpcionConfig(
                icono: Icons.design_services_outlined,
                titulo: 'Servicios',
                subtitulo: 'Gestionar servicios del negocio',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaginaGestionServicios()));
                },
              ),
              const SizedBox(height: 10),
              _OpcionConfig(
                icono: Icons.people_outline,
                titulo: 'Perfiles',
                subtitulo: 'Empleados y clientes registrados',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaginaGestionEmpleados()));
                },
              ),
              const SizedBox(height: 10),
              _OpcionConfig(
                icono: Icons.inventory_2_outlined,
                titulo: 'Inventario',
                subtitulo: 'Agregar, editar y eliminar productos',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaginaInventario()));
                },
              ),
              const SizedBox(height: 10),
              _OpcionConfig(
                icono: Icons.storefront_outlined,
                titulo: 'Inspeccionar Tienda',
                subtitulo: 'Ver la tienda como la ven los clientes',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaginaProductos()));
                },
              ),
              const SizedBox(height: 10),
              _OpcionConfig(
                icono: Icons.percent_rounded,
                titulo: 'Comisiones',
                subtitulo: 'Configurar comisiones por servicio',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaginaConfigComisiones()));
                },
              ),
              const SizedBox(height: 10),
              _OpcionConfig(
                icono: Icons.palette_outlined,
                titulo: 'Color de la aplicación',
                subtitulo: 'Cambia el color principal de la app',
                onTap: () {
                  Navigator.pop(ctx);
                  _mostrarSelectorColor(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSelectorColor(BuildContext context) {
    final config = context.read<ProveedorConfig>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Color de la aplicación',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E))),
            const SizedBox(height: 6),
            const Text('Selecciona el color principal de la app',
                style: TextStyle(fontSize: 13, color: Color(0xFF6E6E73))),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _coloresPreset.length,
              itemBuilder: (ctx, i) {
                final color = _coloresPreset[i];
                final seleccionado = config.colorPrimario.value == color.value;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await config.actualizarColor(color);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: seleccionado
                          ? Border.all(color: const Color(0xFF1C1C1E), width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final nombre = perfil?.nombreCompleto.split(' ').first ?? 'Admin';
    final hoy = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(DateTime.now());

    // ── Cálculos ──────────────────────────────────────────────
    final ingresosServicios = _estEmpleados.fold<double>(
        0, (s, e) => s + ((e['ingresos_totales'] as num?)?.toDouble() ?? 0));
    final totalCompletadas = _estEmpleados.fold<int>(
        0, (s, e) => s + ((e['total_completadas'] as int?) ?? 0));

    final pedidosActivos = _pedidos
        .where((p) => p.estado != EstadoPedido.cancelled)
        .toList();
    final ingresosTienda = pedidosActivos.fold<double>(
        0, (s, p) => s + p.total);
    final pedidosPendientes = _pedidos
        .where((p) => p.estado == EstadoPedido.pending)
        .length;
    final ingresosTotales = ingresosServicios + ingresosTienda;

    return Scaffold(
      backgroundColor: kBackground,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colorPrimario, context.colorPrimario.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hola, $nombre 👋',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hoy,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const PaginaPerfil()),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white.withOpacity(0.25),
                                      backgroundImage: perfil?.urlAvatar != null
                                          ? NetworkImage(perfil!.urlAvatar!)
                                          : null,
                                      child: perfil?.urlAvatar == null
                                          ? Text(
                                              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _cargar,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.refresh_rounded,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Ingreso total destacado ──────────
                          Text(
                            '\$${NumberFormat('#,##0', 'en_US').format(ingresosTotales)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ingresos totales combinados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Acciones rápidas ─────────────────
                          GestureDetector(
                            onTap: () => context.push('/booking/service'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
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
                                    child: Icon(Icons.add_rounded,
                                        color: context.colorPrimario, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Nueva reserva',
                                            style: TextStyle(
                                                color: kText,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        Text('Crear reserva para un cliente',
                                            style: TextStyle(
                                                color: kTextMuted,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14, color: kTextMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Sección: Ingresos separados ──────
                          const _SeccionTitulo('Ingresos por área'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TarjetaIngreso(
                                  titulo: 'Servicios',
                                  monto: ingresosServicios,
                                  icono: Icons.content_cut_rounded,
                                  color: context.colorPrimario,
                                  subtitulo: '$totalCompletadas completados',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TarjetaIngreso(
                                  titulo: 'Tienda',
                                  monto: ingresosTienda,
                                  icono: Icons.shopping_bag_rounded,
                                  color: const Color(0xFF34C759),
                                  subtitulo:
                                      '${pedidosActivos.length} pedidos',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Sección: Stats rápidas ───────────
                          const _SeccionTitulo('Resumen general'),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _TarjetaStat(
                                etiqueta: 'Servicios\ncompletados',
                                valor: '$totalCompletadas',
                                icono: Icons.check_circle_outline_rounded,
                                color: context.colorPrimario,
                              ),
                              _TarjetaStat(
                                etiqueta: 'Empleados\nactivos',
                                valor: '${_estEmpleados.length}',
                                icono: Icons.people_outline_rounded,
                                color: const Color(0xFF007AFF),
                              ),
                              _TarjetaStat(
                                etiqueta: 'Pedidos\npendientes',
                                valor: '$pedidosPendientes',
                                icono: Icons.hourglass_top_rounded,
                                color: const Color(0xFFFF9500),
                              ),
                              _TarjetaStat(
                                etiqueta: 'Servicios\npopulares',
                                valor: '${_serviciosPopulares.length}',
                                icono: Icons.trending_up_rounded,
                                color: const Color(0xFFFF2D55),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Pedidos recientes ────────────────
                          if (_pedidos.isNotEmpty) ...[
                            const _SeccionTitulo('Pedidos recientes'),
                            const SizedBox(height: 12),
                            ..._pedidos.take(4).map(
                                  (p) => _FilaPedido(pedido: p),
                                ),
                            const SizedBox(height: 24),
                          ],

                          // ── Servicios populares ──────────────
                          if (_serviciosPopulares.isNotEmpty) ...[
                            const _SeccionTitulo('Servicios más reservados'),
                            const SizedBox(height: 12),
                            ..._serviciosPopulares.take(5).map(
                                  (s) => _FilaServicio(data: s),
                                ),
                            const SizedBox(height: 24),
                          ],

                          // ── Rendimiento empleados ────────────
                          if (_estEmpleados.isNotEmpty) ...[
                            const _SeccionTitulo('Rendimiento por empleado'),
                            const SizedBox(height: 12),
                            ..._estEmpleados.map(
                                  (e) => _FilaEmpleado(data: e),
                                ),
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String texto;
  const _SeccionTitulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1C1C1E),
        ),
      );
}

class _TarjetaIngreso extends StatelessWidget {
  final String titulo;
  final double monto;
  final IconData icono;
  final Color color;
  final String subtitulo;

  const _TarjetaIngreso({
    required this.titulo,
    required this.monto,
    required this.icono,
    required this.color,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${NumberFormat('#,##0', 'es_ES').format(monto)}',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TarjetaStat extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color color;

  const _TarjetaStat({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1E),
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8E8E93),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaPedido extends StatelessWidget {
  final Pedido pedido;
  const _FilaPedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pedido.estado.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_rounded,
                color: pedido.estado.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.nombreCliente ?? 'Cliente',
                  style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${pedido.items.length} producto${pedido.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: kTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${pedido.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: pedido.estado.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pedido.estado.etiqueta,
                  style: TextStyle(
                      color: pedido.estado.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaServicio extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FilaServicio({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorPrimario.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.content_cut_rounded,
                color: context.colorPrimario, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data['name'] as String? ?? '',
              style: const TextStyle(
                  color: kText, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorPrimario.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${data['veces_reservado'] ?? 0} reservas',
              style: TextStyle(
                  color: context.colorPrimario,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Opción dentro del bottom sheet de configuración ─────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kCardDark2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorPrimario.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: context.colorPrimario, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: kText, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitulo,
                      style: const TextStyle(color: kTextMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: kTextMuted),
          ],
        ),
      ),
    );
  }
}

// ── Tile selector de color ──────────────────────────────────────
class _TileColorApp extends StatelessWidget {
  final VoidCallback onTap;
  const _TileColorApp({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorActual = context.colorPrimario;
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorActual,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorActual.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color de la aplicación',
                      style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('Cambia el color principal de la app',
                      style: TextStyle(color: kTextMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: kTextMuted),
          ],
        ),
      ),
    );
  }
}

class _FilaEmpleado extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FilaEmpleado({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          AvatarRed(nombre: data['full_name'] as String?, radio: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['full_name'] as String? ?? '',
                  style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${data['total_completadas'] ?? 0} servicios completados',
                  style:
                      const TextStyle(color: kTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '\$${(data['ingresos_totales'] as num?)?.toStringAsFixed(0) ?? '0'}',
            style: TextStyle(
                color: context.colorPrimario,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}
