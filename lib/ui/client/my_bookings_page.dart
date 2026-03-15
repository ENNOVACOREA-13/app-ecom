import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaMisReservas extends StatefulWidget {
  const PaginaMisReservas({super.key});

  @override
  State<PaginaMisReservas> createState() => _PaginaMisReservasState();
}

class _PaginaMisReservasState extends State<PaginaMisReservas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idCliente = context.read<ProveedorAuth>().perfil?.id;
      if (idCliente != null) {
        context.read<ProveedorReserva>().cargarReservasCliente(idCliente);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking/service'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Reservas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
            ),
          ),
          Expanded(
            child: proveedor.cargandoReservas
                ? const Center(child: CircularProgressIndicator())
                : proveedor.reservas.isEmpty
              ? const EstadoVacio(
                  icono: Icons.calendar_today_outlined,
                  titulo: 'Sin reservas',
                  subtitulo: 'Crea tu primera reserva',
                )
              : _ListaConSeparadores(
                  reservas: proveedor.reservas.toList()
                    ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva)),
                ),
          ),
        ],
      ),
    );
  }
}

class _ListaConSeparadores extends StatelessWidget {
  final List<Reserva> reservas;
  const _ListaConSeparadores({required this.reservas});

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
    final items = <dynamic>[];
    String? lastLabel;
    for (final r in reservas) {
      final label = _etiquetaDia(r.fechaReserva);
      if (label != lastLabel) {
        items.add(label);
        lastLabel = label;
      }
      items.add(r);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) return _SeparadorDia(etiqueta: item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TarjetaReserva(reserva: item as Reserva),
        );
      },
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
          Text(etiqueta,
              style: const TextStyle(
                  color: Color(0xFF6E6E73),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: const Color(0xFFD1D1D6), thickness: 0.8)),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends StatefulWidget {
  final Reserva reserva;
  const _TarjetaReserva({required this.reserva});

  @override
  State<_TarjetaReserva> createState() => _TarjetaReservaState();
}

class _TarjetaReservaState extends State<_TarjetaReserva> {
  bool _expandida = false;

  Future<void> _cancelar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Seguro que quieres cancelar esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar reserva', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      final perfil = context.read<ProveedorAuth>().perfil!;
      await context.read<ProveedorReserva>().cancelarReserva(
            widget.reserva.id,
            perfil.id,
            motivo: 'Cancelada por el cliente',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(r.fechaReserva);

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
            // Fila principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.nombreServicio ?? 'Servicio'} — ${(r.nombreEmpleado ?? '—').split(' ').first}',
                          style: const TextStyle(
                              color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(fechaTexto,
                            style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                      ],
                    ),
                  ),
                  ChipEstado(etiqueta: r.estado.label, color: r.estado.color),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expandida ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6E6E73), size: 20),
                  ),
                ],
              ),
            ),
            // Detalle expandible
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expandida ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilaDetalle(Icons.badge_outlined, 'Empleado: ${r.nombreEmpleado ?? '—'}'),
                    const SizedBox(height: 6),
                    _FilaDetalle(Icons.access_time_outlined, '${r.horaInicio} – ${r.horaFin}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.attach_money_rounded, size: 14, color: Color(0xFF6E6E73)),
                        const SizedBox(width: 6),
                        Text('\$${r.precioTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                                color: context.colorPrimario,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                    if (r.puedeCancelar) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _cancelar(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Cancelar reserva'),
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
