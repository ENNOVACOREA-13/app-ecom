import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/caja_repository.dart';
import '../../domain/models/caja_model.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';
import '../common/skeleton.dart';
import '../common/toast.dart';

final _fmtFecha = DateFormat("d 'de' MMM, HH:mm", 'es_ES');
final _fmtDinero = NumberFormat('#,##0', 'en_US');

/// El primer corte que se genere siempre arranca "desde el inicio" (sin
/// corte anterior) — el modelo lo representa con la época 1970, así que
/// se muestra como texto en vez de una fecha sin sentido.
String _fmtInicioPeriodo(DateTime fecha) =>
    fecha.year <= 1970 ? 'Desde el inicio' : _fmtFecha.format(fecha.toLocal());

class PaginaReportes extends StatefulWidget {
  const PaginaReportes({super.key});

  @override
  State<PaginaReportes> createState() => _PaginaReportesState();
}

class _PaginaReportesState extends State<PaginaReportes> {
  final _repo = RepositorioCaja();
  List<CorteCaja> _cortes = [];
  bool _cargando = true;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _cortes = await _repo.obtenerCortes();
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _generarCorte() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Generar corte de caja',
            style: TextStyle(color: Color(0xFF1C1C1E))),
        content: const Text(
          'Esto guarda un reporte de todo lo acumulado desde el último '
          'corte (o desde siempre, si es el primero) y hace que el '
          'dashboard vuelva a empezar en 0. No se borra ni se modifica '
          'ningún dato real — reservas, pedidos, comisiones y compras '
          'siguen intactos, este reporte solo queda guardado aquí.',
          style: TextStyle(color: Color(0xFF6E6E73)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar corte'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _generando = true);
    try {
      await _repo.generarCorte();
      if (mounted) {
        mostrarToast(context, 'Corte generado', tipo: TipoToast.exito);
      }
      await _cargar();
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
    if (mounted) setState(() => _generando = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh_outlined)),
        ],
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EntradaAnimada(
                  index: 0,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _generando ? null : _generarCorte,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: kNeumorphicShadowsSmall,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: _generando
                                  ? SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: color))
                                  : Icon(Icons.content_cut, color: color),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Generar corte',
                                      style: TextStyle(
                                          color: Color(0xFF1C1C1E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  Text('Guarda el periodo actual y reinicia el dashboard',
                                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Color(0xFF8E8E93)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Historial de cortes',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                if (_cargando)
                  const ListaEsqueleto()
                else if (_cortes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EstadoVacio(
                      icono: Icons.receipt_long_outlined,
                      titulo: 'Sin cortes todavía',
                      subtitulo: 'Genera el primero cuando quieras cerrar el periodo actual',
                    ),
                  )
                else
                  ..._cortes.asMap().entries.map((e) => EntradaAnimada(
                        index: e.key + 1,
                        child: _FilaCorte(corte: e.value),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaCorte extends StatelessWidget {
  final CorteCaja corte;
  const _FilaCorte({required this.corte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaginaDetalleCorte(corte: corte)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_fmtInicioPeriodo(corte.periodoDesde)} — ${_fmtFecha.format(corte.periodoHasta.toLocal())}',
                        style: const TextStyle(
                            color: Color(0xFF1C1C1E), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text('${corte.serviciosCompletados} servicios · ${corte.pedidosTotal} pedidos',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${_fmtDinero.format(corte.ingresosTotales)}',
                        style: TextStyle(
                            color: context.colorPrimario, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('ganancia \$${_fmtDinero.format(corte.gananciasNetas)}',
                        style: const TextStyle(color: Color(0xFF34C759), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaginaDetalleCorte extends StatefulWidget {
  final CorteCaja corte;
  const PaginaDetalleCorte({super.key, required this.corte});

  @override
  State<PaginaDetalleCorte> createState() => _PaginaDetalleCorteState();
}

class _PaginaDetalleCorteState extends State<PaginaDetalleCorte> {
  final _repo = RepositorioCaja();
  List<EmpleadoCorte> _empleados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      _empleados = await _repo.obtenerDetalleEmpleadosCorte(widget.corte.id);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.corte;
    final color = context.colorPrimario;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Detalle del corte')),
      body: EnvolturaResponsiva(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${_fmtInicioPeriodo(c.periodoDesde)} — ${_fmtFecha.format(c.periodoHasta.toLocal())}',
                style: const TextStyle(
                    color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _Tarjeta(
                      titulo: 'Servicios',
                      monto: c.ingresosServicios,
                      subtitulo: '${c.serviciosCompletados} completados',
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tarjeta(
                      titulo: 'Tienda',
                      monto: c.ingresosTienda,
                      subtitulo: '${c.pedidosTotal} pedidos',
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kNeumorphicShadowsSmall,
                ),
                child: Column(
                  children: [
                    _filaResumen('Ingresos totales', c.ingresosTotales, positivo: true),
                    const Divider(height: 20),
                    _filaResumen('Comisiones pendientes', -c.comisionesPendientes),
                    _filaResumen('Insumos comprados', -c.insumosComprados),
                    const Divider(height: 20),
                    _filaResumen('Ganancias netas', c.gananciasNetas, destacado: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Tarjeta(
                titulo: 'Pedidos pendientes',
                monto: null,
                valorTexto: '${c.pedidosPendientes}',
                subtitulo: 'al momento del corte',
                color: const Color(0xFFFF9500),
              ),
              const SizedBox(height: 24),
              if (_cargando)
                const ListaEsqueleto()
              else if (_empleados.isNotEmpty) ...[
                const Text('Ingresos por empleado',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                ..._empleados.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: kNeumorphicShadowsSmall,
                      ),
                      child: Row(
                        children: [
                          AvatarRed(nombre: e.nombreEmpleado, radio: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.nombreEmpleado,
                                    style: const TextStyle(
                                        color: Color(0xFF1C1C1E),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text('${e.serviciosCompletados} servicios · comisión pagada \$${e.comisiones.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('\$${e.ingresos.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaResumen(String etiqueta, double monto,
      {bool positivo = false, bool destacado = false}) {
    final esNegativo = monto < 0 && !positivo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              style: TextStyle(
                  color: destacado ? const Color(0xFF1C1C1E) : const Color(0xFF6E6E73),
                  fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
                  fontSize: destacado ? 15 : 13)),
          Text(
            '${monto < 0 ? '-' : '+'}\$${_fmtDinero.format(monto.abs())}',
            style: TextStyle(
                color: destacado
                    ? const Color(0xFF34C759)
                    : (esNegativo ? Colors.red : const Color(0xFF1C1C1E)),
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
                fontSize: destacado ? 17 : 13),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final double? monto;
  final String? valorTexto;
  final String subtitulo;
  final Color color;

  const _Tarjeta({
    required this.titulo,
    this.monto,
    this.valorTexto,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            valorTexto ?? '\$${_fmtDinero.format(monto ?? 0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(subtitulo, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
        ],
      ),
    );
  }
}
