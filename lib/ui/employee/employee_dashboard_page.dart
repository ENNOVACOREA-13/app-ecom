import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/booking_repository.dart';
import '../../data/caja_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commission_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/service_provider.dart';
import '../../domain/models/commission_model.dart';
import '../../domain/models/caja_model.dart';
import '../../core/constants.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';

class PaginaTableroEmpleado extends StatefulWidget {
  const PaginaTableroEmpleado({super.key});

  @override
  State<PaginaTableroEmpleado> createState() => PaginaTableroEmpleadoState();
}

class PaginaTableroEmpleadoState extends State<PaginaTableroEmpleado> {
  final _repoCaja = RepositorioCaja();
  final _repoReserva = RepositorioReserva();
  ResumenPeriodoEmpleado? _estadisticas;
  bool _cargando = true;
  bool _enviandoSinCita = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> recargar() => _cargar();

  Future<void> _reportarSinCita() async {
    final servicioProv = context.read<ProveedorServicio>();
    if (servicioProv.servicios.isEmpty) {
      await servicioProv.cargarServicios();
    }
    if (!mounted) return;
    final servicios = servicioProv.servicios;

    String? servicioId;
    final notaCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Servicio sin cita',
              style: TextStyle(color: Color(0xFF1C1C1E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le avisa al admin que hiciste un servicio sin reserva '
                  'registrada, para que la meta manualmente y el corte '
                  'semanal cuadre con lo cobrado.',
                  style: TextStyle(color: Color(0xFF6E6E73), height: 1.4),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: servicioId,
                  decoration: const InputDecoration(
                    labelText: '¿Qué servicio hiciste?',
                    border: OutlineInputBorder(),
                  ),
                  items: servicios
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre,
                                style: const TextStyle(color: Color(0xFF1C1C1E))),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => servicioId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notaCtrl,
                  maxLength: 140,
                  maxLines: 2,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: servicioId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Enviar aviso'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true || servicioId == null || !mounted) return;

    setState(() => _enviandoSinCita = true);
    try {
      await _repoReserva.reportarServicioSinCita(servicioId!,
          nota: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim());
      if (mounted) {
        mostrarToast(context, 'Aviso enviado al admin', tipo: TipoToast.exito);
      }
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
    if (mounted) setState(() => _enviandoSinCita = false);
  }

  Future<void> _cargar() async {
    final id = context.read<ProveedorAuth>().perfil?.id;
    if (id == null) return;
    try {
      // Periodo actual (desde el último corte de caja) — antes era la
      // vista employee_stats, de toda la vida.
      final estadisticas = await _repoCaja.obtenerResumenActualEmpleado();
      if (mounted) {
        setState(() {
          _estadisticas = estadisticas;
          _cargando = false;
        });
        context.read<ProveedorComision>().cargarPendientesEmpleado(id);
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final comision = context.watch<ProveedorComision>();
    final logoUrl = context.watch<ProveedorConfig>().logoUrl;

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  EntradaAnimada(
                    index: 0,
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.colorPrimario, context.colorPrimario.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Text('Empleado', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const IconoNotificaciones(color: Colors.white),
                        const SizedBox(width: 14),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl)
                              : AssetImage(kLogoBarberiaAsset) as ImageProvider,
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  EntradaAnimada(
                    index: 1,
                    child: TarjetaPresionable(
                      onTap: _enviandoSinCita ? null : _reportarSinCita,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
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
                              child: _enviandoSinCita
                                  ? SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: context.colorPrimario))
                                  : Icon(Icons.report_gmailerrorred_outlined,
                                      color: context.colorPrimario, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sin cita',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF1C1C1E))),
                                  SizedBox(height: 2),
                                  Text('Avisa al admin que hiciste un servicio sin reserva',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
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

                  const SizedBox(height: 28),

                  // ── Comisiones pendientes de corte ────────
                  EntradaAnimada(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Comisiones',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E))),
                        const SizedBox(height: 12),
                        _TarjetaComisionSemana(prov: comision),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  EntradaAnimada(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estadísticas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                        const SizedBox(height: 16),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          children: [
                            TarjetaEstadistica(
                              etiqueta: 'Completadas',
                              valor: '${_estadisticas?.serviciosCompletados ?? 0}',
                              icono: Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            TarjetaEstadistica(
                              etiqueta: 'Pendientes',
                              valor: '${_estadisticas?.serviciosPendientes ?? 0}',
                              icono: Icons.hourglass_empty_outlined,
                              color: Colors.orange,
                            ),
                            TarjetaEstadistica(
                              etiqueta: 'Canceladas',
                              valor: '${_estadisticas?.serviciosCancelados ?? 0}',
                              icono: Icons.cancel_outlined,
                              color: Colors.red,
                            ),
                            TarjetaEstadistica(
                              etiqueta: 'Ingresos',
                              valor: '\$${(_estadisticas?.ingresos ?? 0).toStringAsFixed(0)}',
                              icono: Icons.attach_money,
                              color: context.colorPrimario,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (comision.cortes.isNotEmpty)
                    EntradaAnimada(
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text('Cortes anteriores',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1E))),
                          const SizedBox(height: 12),
                          ...() {
                            // El "mejor corte" se calcula sobre TODO el
                            // historial, no solo los 5 que se muestran — para
                            // que el destacado sea real aunque el corte más
                            // grande ya no aparezca en la lista visible.
                            final mejorId = comision.cortes.length > 1
                                ? comision.cortes
                                    .reduce((a, b) => b.montoTotal > a.montoTotal ? b : a)
                                    .id
                                : null;
                            return comision.cortes.take(5).map(
                                  (c) => _FilaCorteEmpleado(
                                      corte: c, esMejor: c.id == mejorId),
                                );
                          }(),
                        ],
                      ),
                    ),

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

    final total = prov.totalPendienteEmpleado;
    final cantidad = prov.serviciosPendientesEmpleado;

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
              // No es "esta semana": es TODO lo pendiente de corte, sin
              // importar cuándo se ganó — así nunca desaparece nada de la
              // vista sin que un corte real lo haya liquidado.
              const Text(
                'Pendiente de corte',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
          if (prov.entradasPendientes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            ...prov.entradasPendientes.take(5).map((e) => Padding(
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
            if (prov.entradasPendientes.length > 5)
              Text(
                '+ ${prov.entradasPendientes.length - 5} más...',
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
  final bool esMejor;
  const _FilaCorteEmpleado({required this.corte, this.esMejor = false});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM', 'es_ES');
    const dorado = Color(0xFFB8860B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: esMejor ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: esMejor ? Border.all(color: dorado.withOpacity(0.4)) : null,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (esMejor) ...[
                  const Row(
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text('Tu mejor corte',
                          style: TextStyle(
                              color: dorado,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${fmt.format(corte.inicioSemana)} – ${fmt.format(corte.finSemana)}',
                  style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 13),
                ),
              ],
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
