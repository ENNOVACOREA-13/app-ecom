import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/commission_model.dart';
import '../../providers/commission_provider.dart';
import '../../providers/service_provider.dart';
import '../common/toast.dart';

class PaginaConfigComisiones extends StatefulWidget {
  const PaginaConfigComisiones({super.key});

  @override
  State<PaginaConfigComisiones> createState() => _PaginaConfigComisionesState();
}

class _PaginaConfigComisionesState extends State<PaginaConfigComisiones>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorComision>().cargarAdmin();
      context.read<ProveedorServicio>().cargarServicios(esVistaAdmin: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return Scaffold(
      backgroundColor: kBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: kBackground,
            foregroundColor: kColorSobreFondo,
            iconTheme: IconThemeData(color: kColorSobreFondo),
            actionsIconTheme: IconThemeData(color: kColorSobreFondo),
            centerTitle: true,
            title: Text(
              'Comisiones',
              style: TextStyle(
                color: kColorSobreFondo,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabs,
                indicatorColor: color,
                indicatorWeight: 3,
                labelColor: color,
                unselectedLabelColor: const Color(0xFF8E8E93),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Por servicio'),
                  Tab(text: 'Cortes'),
                  Tab(text: 'Ajustes'),
                ],
              ),
            ),
          ),
        ],
        body: EnvolturaResponsiva(
          child: TabBarView(
          controller: _tabs,
          children: const [
            _TabConfiguracion(),
            _TabCortes(),
            _TabAjustes(),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Tab 1: Configurar $ por servicio ──────────────────────────────

class _TabConfiguracion extends StatelessWidget {
  const _TabConfiguracion();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorComision>();
    final servicios = context.watch<ProveedorServicio>().servicios;

    if (prov.cargando && prov.configuraciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final conComision = servicios.where((s) => prov.montoPorServicio(s.id) > 0).length;

    return CustomScrollView(
      slivers: [
        // Banner resumen
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: EntradaAnimada(
              index: 0,
              child: _BannerResumen(
                total: conComision,
                totalServicios: servicios.length,
              ),
            ),
          ),
        ),

        // Lista de servicios
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final s = servicios[i];
                final monto = prov.montoPorServicio(s.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EntradaAnimada(
                    index: i + 1,
                    child: _TarjetaServicioComision(
                      servicio: s,
                      monto: monto,
                      onEditar: () =>
                          _mostrarDialogoMonto(context, prov, s, monto),
                    ),
                  ),
                );
              },
              childCount: servicios.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoMonto(
    BuildContext context,
    ProveedorComision prov,
    ModeloServicio servicio,
    double montoActual,
  ) async {
    final ctrl = TextEditingController(
        text: montoActual > 0 ? montoActual.toStringAsFixed(2) : '');
    final clave = GlobalKey<FormState>();
    final color = context.colorPrimario;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: clave,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Encabezado
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.content_cut_rounded,
                          color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(servicio.nombre,
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17)),
                          Text(
                            '\$${servicio.precio.toStringAsFixed(0)} · ${servicio.etiquetaDuracion}',
                            style: const TextStyle(
                                color: Color(0xFF8E8E93), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo de monto
                const Text('Comisión por servicio',
                    style: TextStyle(
                        color: Color(0xFF3C3C43),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  maxLength: 10,
                  style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                    hintText: '0.00',
                    hintStyle: const TextStyle(
                        color: Color(0xFFD1D1D6),
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null) return 'Número inválido';
                    if (n < 0) return 'No puede ser negativo';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escribe 0 para quitar la comisión',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Color(0xFF8E8E93))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (clave.currentState!.validate()) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Guardar',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && context.mounted) {
      try {
        final valor = double.parse(ctrl.text.isEmpty ? '0' : ctrl.text);
        if (valor == 0) {
          await prov.eliminarConfiguracion(servicio.id);
        } else {
          await prov.guardarConfiguracion(servicio.id, valor);
        }
        if (context.mounted) {
          mostrarToast(context, 'Comisión guardada', tipo: TipoToast.exito);
        }
      } catch (e) {
        if (context.mounted) {
          mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
        }
      }
    }
    ctrl.dispose();
  }
}

class _BannerResumen extends StatelessWidget {
  final int total;
  final int totalServicios;
  const _BannerResumen({required this.total, required this.totalServicios});

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.percent_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total de $totalServicios servicios',
                style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const Text(
                'tienen comisión configurada',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaServicioComision extends StatelessWidget {
  final ModeloServicio servicio;
  final double monto;
  final VoidCallback onEditar;

  const _TarjetaServicioComision({
    required this.servicio,
    required this.monto,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final tieneComision = monto > 0;
    final color = context.colorPrimario;

    return GestureDetector(
      onTap: onEditar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: tieneComision
              ? Border.all(color: color.withOpacity(0.3), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: tieneComision
                  ? color.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: tieneComision
                      ? color.withOpacity(0.1)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.content_cut_rounded,
                  color: tieneComision ? color : const Color(0xFFAEAEB2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${servicio.precio.toStringAsFixed(0)} · ${servicio.etiquetaDuracion}',
                      style: const TextStyle(
                          color: Color(0xFF8E8E93), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Badge de comisión
              if (tieneComision)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: Color(0xFFAEAEB2)),
                      SizedBox(width: 4),
                      Text('Asignar',
                          style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 2: Cortes semanales ──────────────────────────────────────

class _TabCortes extends StatelessWidget {
  const _TabCortes();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorComision>();

    return CustomScrollView(
      slivers: [
        // Resumen de lo pendiente de corte (no solo la semana actual)
        if (prov.resumenAdmin.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: EntradaAnimada(
                  index: 0, child: _TarjetaResumenSemana(resumen: prov.resumenAdmin)),
            ),
          ),

        // Botón procesar corte
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: EntradaAnimada(index: 1, child: _BotonProcesarCorte(prov: prov)),
          ),
        ),

        // Encabezado historial
        if (prov.cortes.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Text('Historial de cortes',
                  style: TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),

        // Lista de cortes
        if (prov.cortes.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('Sin cortes registrados',
                  style: TextStyle(color: Color(0xFF8E8E93))),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EntradaAnimada(
                    index: i + 2,
                    child: _TarjetaCorte(
                      corte: prov.cortes[i],
                      onPagar: () => _marcarPagado(context, prov, prov.cortes[i]),
                    ),
                  ),
                ),
                childCount: prov.cortes.length,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _marcarPagado(
      BuildContext context, ProveedorComision prov, CorteComision corte) async {
    if (corte.estaPagado) return;
    final ctrlNotas = TextEditingController();
    final color = context.colorPrimario;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Registrar pago',
                  style: TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        (corte.nombreEmpleado ?? 'E')[0].toUpperCase(),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(corte.nombreEmpleado ?? 'Empleado',
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${corte.cantidadServicios} servicios completados',
                            style: const TextStyle(
                                color: Color(0xFF8E8E93), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${corte.montoTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrlNotas,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Notas (método de pago, referencia...)',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  counterText: '',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Color(0xFF8E8E93))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Confirmar pago',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await prov.marcarCortePagado(corte.id,
            notas: ctrlNotas.text.trim().isEmpty
                ? null
                : ctrlNotas.text.trim());
        if (context.mounted) {
          mostrarToast(context, 'Pago registrado', tipo: TipoToast.exito);
        }
      } catch (e) {
        if (context.mounted) {
          mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
        }
      }
    }
    ctrlNotas.dispose();
  }
}

class _BotonProcesarCorte extends StatelessWidget {
  final ProveedorComision prov;
  const _BotonProcesarCorte({required this.prov});

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return GestureDetector(
      onTap: prov.cargando ? null : () => _confirmarCorte(context, prov),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.cut_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Procesar corte',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(
                    'Liquida todo lo pendiente, sin importar la fecha',
                    style: TextStyle(
                        color: color.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            prov.cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: color, size: 16),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarCorte(
      BuildContext context, ProveedorComision prov) async {
    final hoy = DateTime.now();
    final fmt = DateFormat('dd MMM yyyy', 'es_ES');
    final color = context.colorPrimario;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cut_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Confirmar corte',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          'Se liquidará TODO lo pendiente de corte hasta hoy (${fmt.format(hoy)}), '
          'incluyendo semanas anteriores si las hay, para todos los empleados con servicios completados.',
          style: const TextStyle(
              color: Color(0xFF3C3C43), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Procesar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await prov.procesarCorte(hoy);
        if (context.mounted) {
          mostrarToast(context, 'Corte procesado correctamente', tipo: TipoToast.exito);
        }
      } catch (e) {
        if (context.mounted) {
          mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
        }
      }
    }
  }
}

class _TarjetaResumenSemana extends StatelessWidget {
  final List<Map<String, dynamic>> resumen;
  const _TarjetaResumenSemana({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final total = resumen.fold<double>(0, (s, e) => s + (e['total'] as double));
    final color = context.colorPrimario;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pendiente de corte',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${resumen.length} empleado${resumen.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1),
          ),
          const SizedBox(height: 4),
          const Text('Total a pagar en comisiones',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          if (resumen.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            ...resumen.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          ((e['full_name'] as String?) ?? 'E')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e['full_name'] as String? ?? 'Empleado',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Text(
                        '\$${(e['total'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${e['count']} serv.',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _TarjetaCorte extends StatelessWidget {
  final CorteComision corte;
  final VoidCallback onPagar;

  const _TarjetaCorte({required this.corte, required this.onPagar});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM', 'es_ES');
    final pagado = corte.estaPagado;
    final colorEstado =
        pagado ? const Color(0xFF34C759) : const Color(0xFFFF9500);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              pagado
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: colorEstado,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  corte.nombreEmpleado ?? 'Empleado',
                  style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  '${fmt.format(corte.inicioSemana)} – ${fmt.format(corte.finSemana)} · ${corte.cantidadServicios} serv.',
                  style: const TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 11),
                ),
                if (corte.notas != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(corte.notas!,
                        style: const TextStyle(
                            color: Color(0xFFAEAEB2), fontSize: 11)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${corte.montoTotal.toStringAsFixed(2)}',
                style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.w900,
                    fontSize: 16),
              ),
              const SizedBox(height: 6),
              if (!pagado)
                GestureDetector(
                  onTap: onPagar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Pagar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Pagado',
                      style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Ajustes de cierre ──────────────────────────────────────

class _TabAjustes extends StatefulWidget {
  const _TabAjustes();

  @override
  State<_TabAjustes> createState() => _TabAjustesState();
}

class _TabAjustesState extends State<_TabAjustes> {
  int? _diaSel;
  int? _horaSel;
  int? _minSel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ajustes = context.read<ProveedorComision>().ajustes;
    if (ajustes != null && _diaSel == null) {
      _diaSel = ajustes.diaCierre;
      _horaSel = ajustes.horaCierre;
      _minSel = ajustes.minutoCierre;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorComision>();
    final ajustes = prov.ajustes;
    final color = context.colorPrimario;

    if (ajustes == null && prov.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ajustes == null) {
      return const Center(
        child: Text('No se encontraron ajustes',
            style: TextStyle(color: Color(0xFF8E8E93))),
      );
    }

    _diaSel ??= ajustes.diaCierre;
    _horaSel ??= ajustes.horaCierre;
    _minSel ??= ajustes.minutoCierre;

    const diasSemana = [
      'Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'
    ];
    const diasCompletos = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El corte se procesará automáticamente cada '
                    '${diasCompletos[_diaSel ?? 0]} a las '
                    '${(_horaSel ?? 23).toString().padLeft(2, '0')}:${(_minSel ?? 59).toString().padLeft(2, '0')}',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Día de cierre
          const Text('Día de cierre',
              style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final sel = _diaSel == i;
              return GestureDetector(
                onTap: () => setState(() => _diaSel = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 52,
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Center(
                    child: Text(
                      diasSemana[i],
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF8E8E93),
                        fontWeight:
                            sel ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Hora de cierre
          const Text('Hora de cierre',
              style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RuedaNumero(
                  valor: _horaSel ?? 23,
                  min: 0,
                  max: 23,
                  onCambio: (v) => setState(() => _horaSel = v),
                  color: color,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(':',
                      style: TextStyle(
                          color: color,
                          fontSize: 40,
                          fontWeight: FontWeight.w900)),
                ),
                _RuedaNumero(
                  valor: _minSel ?? 59,
                  min: 0,
                  max: 59,
                  step: 5,
                  onCambio: (v) => setState(() => _minSel = v),
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: prov.cargando ? null : () => _guardar(context, prov),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Guardar ajustes',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar(BuildContext context, ProveedorComision prov) async {
    try {
      await prov.guardarAjustes(
        diaCierre: _diaSel!,
        horaCierre: _horaSel!,
        minutoCierre: _minSel!,
      );
      if (context.mounted) {
        mostrarToast(context, 'Ajustes guardados', tipo: TipoToast.exito);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
  }
}

class _RuedaNumero extends StatelessWidget {
  final int valor;
  final int min;
  final int max;
  final int step;
  final Color color;
  final ValueChanged<int> onCambio;

  const _RuedaNumero({
    required this.valor,
    required this.min,
    required this.max,
    this.step = 1,
    required this.color,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: valor + step <= max ? () => onCambio(valor + step) : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.keyboard_arrow_up_rounded,
                color: color, size: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          valor.toString().padLeft(2, '0'),
          style: TextStyle(
              color: color,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: valor - step >= min ? () => onCambio(valor - step) : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: color, size: 24),
          ),
        ),
      ],
    );
  }
}
