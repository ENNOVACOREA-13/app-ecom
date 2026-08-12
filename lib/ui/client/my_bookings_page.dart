import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../common/app_widgets.dart';
import 'booking_detail_page.dart';

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
      appBar: AppBar(title: const Text('Reservas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking/service'),
        backgroundColor: context.colorPrimario,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: _TarjetaReserva(
                  key: ValueKey((item as Reserva).id), reserva: item),
            ),
          );
        }).toList(),
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

class _TarjetaReserva extends StatelessWidget {
  final Reserva reserva;
  const _TarjetaReserva({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(r.fechaReserva);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaginaDetalleReserva(reserva: r)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6E6E73), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
