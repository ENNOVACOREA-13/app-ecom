import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/booking_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commission_provider.dart';
import '../../domain/models/commission_model.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaTableroEmpleado extends StatefulWidget {
  const PaginaTableroEmpleado({super.key});

  @override
  State<PaginaTableroEmpleado> createState() => _PaginaTableroEmpleadoState();
}

class _PaginaTableroEmpleadoState extends State<PaginaTableroEmpleado> {
  final _repo = RepositorioReserva();
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = context.read<ProveedorAuth>().perfil?.id;
    if (id == null) return;
    try {
      final estadisticas = await _repo.obtenerEstadisticasEmpleado(id);
      if (mounted) {
        setState(() {
          _estadisticas = estadisticas;
          _cargando = false;
        });
        context.read<ProveedorComision>().cargarSemanaEmpleado(id);
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final comision = context.watch<ProveedorComision>();

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryLight, kCard],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: kNeumorphicShadows,
                    ),
                    child: Row(
                      children: [
                        AvatarRed(url: perfil?.urlAvatar, nombre: perfil?.nombreCompleto, radio: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfil?.nombreCompleto ?? '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: kText),
                              ),
                              const Text('Empleado', style: TextStyle(color: kTextSub)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Estadísticas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      TarjetaEstadistica(
                        etiqueta: 'Completadas',
                        valor: '${_estadisticas['total_completadas'] ?? 0}',
                        icono: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Pendientes',
                        valor: '${_estadisticas['total_pendientes'] ?? 0}',
                        icono: Icons.hourglass_empty_outlined,
                        color: Colors.orange,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Canceladas',
                        valor: '${_estadisticas['total_canceladas'] ?? 0}',
                        icono: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Ingresos',
                        valor: '\$${(_estadisticas['ingresos_totales'] ?? 0).toStringAsFixed(0)}',
                        icono: Icons.attach_money,
                        color: kPrimary,
                      ),
                    ],
                  ),

                  if (_estadisticas['rating_promedio'] != null) ...[
                    const SizedBox(height: 24),
                    TarjetaSeccion(
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_estadisticas['rating_promedio']}',
                                style: const TextStyle(
                                    color: kText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_estadisticas['total_reviews'] ?? 0} reseñas',
                                style: const TextStyle(color: kTextSub, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Comisiones semana actual ──────────────
                  const SizedBox(height: 28),
                  const Text('Comisiones esta semana',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 12),
                  _TarjetaComisionSemana(prov: comision),

                  if (comision.cortes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Cortes anteriores',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 12),
                    ...comision.cortes.take(5).map(
                          (c) => _FilaCorteEmpleado(corte: c),
                        ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _TarjetaComisionSemana extends StatelessWidget {
  final ProveedorComision prov;
  const _TarjetaComisionSemana({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = prov.totalSemanaEmpleado;
    final cantidad = prov.serviciosSemanaEmpleado;
    final ahora = DateTime.now();
    final diasDesdeLunes = ahora.weekday - 1;
    final inicioSemana = DateTime(ahora.year, ahora.month, ahora.day - diasDesdeLunes);
    final finSemana = inicioSemana.add(const Duration(days: 6));
    final fmt = DateFormat('dd MMM', 'es_ES');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorPrimario,
            context.colorPrimario.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.colorPrimario.withOpacity(0.3),
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
              const Text('Acumulado',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(
                '${fmt.format(inicioSemana)} – ${fmt.format(finSemana)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            '$cantidad servicio${cantidad == 1 ? '' : 's'} completado${cantidad == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (prov.entradasSemana.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            ...prov.entradasSemana.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e.nombreServicio,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '+\$${e.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                )),
            if (prov.entradasSemana.length > 5)
              Text(
                '+ ${prov.entradasSemana.length - 5} más...',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilaCorteEmpleado extends StatelessWidget {
  final CorteComision corte;
  const _FilaCorteEmpleado({required this.corte});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM', 'es_ES');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          Icon(
            corte.estaPagado
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            color: corte.estaPagado
                ? const Color(0xFF34C759)
                : const Color(0xFFFF9500),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${fmt.format(corte.inicioSemana)} – ${fmt.format(corte.finSemana)}',
              style: const TextStyle(color: kText, fontSize: 13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${corte.montoTotal.toStringAsFixed(2)}',
                style: TextStyle(
                    color: corte.estaPagado
                        ? const Color(0xFF34C759)
                        : context.colorPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
              Text(
                corte.estaPagado ? 'Pagado' : 'Pendiente',
                style: TextStyle(
                    color: corte.estaPagado
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
