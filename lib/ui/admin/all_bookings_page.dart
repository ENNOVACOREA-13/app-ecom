import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../common/app_widgets.dart';
import '../common/skeleton.dart';
import '../common/toast.dart';
import '../employee/scan_qr_page.dart';

class PaginaTodasReservas extends StatefulWidget {
  const PaginaTodasReservas({super.key});

  @override
  State<PaginaTodasReservas> createState() => _PaginaTodasReservasState();
}

class _PaginaTodasReservasState extends State<PaginaTodasReservas> {
  EstadoReserva? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorReserva>().cargarTodasLasReservas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();
    final filtradas = (_filtro == null
        ? proveedor.reservas.toList()
        : proveedor.reservas.where((b) => b.estado == _filtro).toList())
      ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear QR',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaEscanearQR()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => proveedor.cargarTodasLasReservas(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/booking/service'),
        backgroundColor: context.colorPrimario,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva reserva',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: EnvolturaResponsiva(
        child: Column(
        children: [
          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _ChipFiltro(label: 'Todas', selected: _filtro == null,
                    onTap: () => setState(() => _filtro = null)),
                const SizedBox(width: 8),
                ...EstadoReserva.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChipFiltro(
                        label: s.label,
                        selected: _filtro == s,
                        onTap: () => setState(() => _filtro = s),
                      ),
                    )),
              ],
            ),
          ),

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtradas.length} reservas',
                  style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: proveedor.cargandoReservas
                ? const ListaEsqueleto()
                : filtradas.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.calendar_today_outlined,
                        titulo: 'Sin reservas',
                      )
                    : _ListaConSeparadores(
                        reservas: filtradas,
                        hayMas: proveedor.hayMasReservasAdmin,
                        cargandoMas: proveedor.cargandoMasReservas,
                        onCargarMas: () => proveedor.cargarMasReservas(),
                      ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ListaConSeparadores extends StatelessWidget {
  final List<Reserva> reservas;
  final bool hayMas;
  final bool cargandoMas;
  final VoidCallback onCargarMas;
  const _ListaConSeparadores({
    required this.reservas,
    required this.hayMas,
    required this.cargandoMas,
    required this.onCargarMas,
  });

  String _etiquetaDia(DateTime fecha) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    if (_mismoDia(fecha, hoy)) return 'Hoy';
    if (_mismoDia(fecha, ayer)) return 'Ayer';
    return DateFormat('dd MMM yyyy', 'es_ES').format(fecha);
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Build mixed list: [header, card, card, header, card, ...]
    final items = <dynamic>[];
    String? lastLabel;
    for (final r in reservas) {
      final label = _etiquetaDia(r.fechaReserva);
      if (label != lastLabel) {
        items.add(label); // separator header
        lastLabel = label;
      }
      items.add(r);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          if (item is String) return _SeparadorDia(etiqueta: item);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EntradaAnimada(
              index: entry.key,
              child: _TarjetaReservaAdmin(
                  key: ValueKey((item as Reserva).id), reserva: item),
            ),
          );
        }).toList()
          ..addAll(hayMas
              ? [BotonCargarMas(cargando: cargandoMas, onTap: onCargarMas)]
              : const []),
      ),
    );
  }
}

class _SeparadorDia extends StatelessWidget {
  final String etiqueta;
  const _SeparadorDia({required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: const Color(0xFFD1D1D6), thickness: 0.8)),
          const SizedBox(width: 10),
          Text(
            etiqueta,
            style: const TextStyle(
              color: Color(0xFF6E6E73),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: const Color(0xFFD1D1D6), thickness: 0.8)),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipFiltro({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? context.colorPrimario : kCard,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: kDivider, width: 0.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: context.colorPrimario.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ]
              : kNeumorphicShadowsSmall,
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : kTextSub,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}

class _TarjetaReservaAdmin extends StatefulWidget {
  final Reserva reserva;
  const _TarjetaReservaAdmin({super.key, required this.reserva});

  @override
  State<_TarjetaReservaAdmin> createState() => _TarjetaReservaAdminState();
}

class _TarjetaReservaAdminState extends State<_TarjetaReservaAdmin> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(r.fechaReserva);
    final inicial = (r.nombreCliente ?? '?')[0].toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // ── Fila principal (siempre visible) ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icono de servicio
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.content_cut_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Servicio + fecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.nombreServicio ?? 'Servicio'} — ${(r.nombreEmpleado ?? '—').split(' ').first}',
                          style: const TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fechaTexto,
                          style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Avatar del cliente
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.colorPrimario.withOpacity(0.15),
                    child: Text(inicial,
                        style: TextStyle(
                            color: context.colorPrimario,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 10),

                  // Estado
                  if (r.cancelacionSolicitada) ...[
                    const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                  ],
                  ChipEstado(etiqueta: r.estado.label, color: r.estado.color),
                  const SizedBox(width: 8),

                  // Flecha
                  AnimatedRotation(
                    turns: _expandida ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6E6E73), size: 20),
                  ),
                ],
              ),
            ),

            // ── Detalle expandible ─────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expandida
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilaDetalle(Icons.person_outline,
                        'Cliente: ${r.nombreCliente ?? '—'}'),
                    const SizedBox(height: 6),
                    _FilaDetalle(Icons.badge_outlined,
                        'Empleado: ${r.nombreEmpleado ?? '—'}'),
                    const SizedBox(height: 6),
                    _FilaDetalle(Icons.access_time_outlined,
                        '${r.horaInicio} – ${r.horaFin}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.attach_money_rounded,
                            size: 14, color: Color(0xFF6E6E73)),
                        const SizedBox(width: 6),
                        Text(
                          '\$${r.precioTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: context.colorPrimario,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    if (r.estado == EstadoReserva.pending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context
                                  .read<ProveedorReserva>()
                                  .actualizarEstado(r.id, EstadoReserva.confirmed),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: context.colorPrimario,
                                  side: BorderSide(color: context.colorPrimario)),
                              child: const Text('Confirmar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final perfil = context.read<ProveedorAuth>().perfil!;
                                context.read<ProveedorReserva>().cancelarReserva(
                                      r.id, perfil.id,
                                      motivo: 'Cancelada por admin');
                              },
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red)),
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (r.estado == EstadoReserva.confirmed && r.cancelacionSolicitada) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('El cliente solicitó cancelar esta reserva',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context
                                        .read<ProveedorReserva>()
                                        .rechazarSolicitudCancelacion(r.id),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF6E6E73),
                                        side: const BorderSide(color: Color(0xFFD1D1D6))),
                                    child: const Text('Rechazar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final perfil = context.read<ProveedorAuth>().perfil!;
                                      context.read<ProveedorReserva>().cancelarReserva(
                                            r.id, perfil.id,
                                            motivo: 'Cancelación aprobada por admin');
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10))),
                                    child: const Text('Aprobar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (r.estado == EstadoReserva.confirmed) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF34C759)),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text('Escanea el QR del cliente para marcarla como pagada',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // El admin, a diferencia del empleado, también puede
                      // marcarla como pagada manualmente (sin QR) — pedido
                      // explícito 2026-08-21.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await context
                                  .read<ProveedorReserva>()
                                  .actualizarEstado(r.id, EstadoReserva.completed);
                              if (context.mounted) {
                                mostrarToast(context, 'Reserva marcada como pagada',
                                    tipo: TipoToast.exito);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Marcar como pagada manualmente'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF34C759),
                              side: const BorderSide(color: Color(0xFF34C759))),
                        ),
                      ),
                    ],
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

class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _FilaDetalle(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 14, color: const Color(0xFF6E6E73)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto,
              style: const TextStyle(color: Color(0xFF3C3C43), fontSize: 12)),
        ),
      ],
    );
  }
}
