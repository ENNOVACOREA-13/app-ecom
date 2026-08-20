import 'package:flutter/material.dart';
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
import 'booking_detail_page.dart';

class PaginaTickets extends StatefulWidget {
  const PaginaTickets({super.key});

  @override
  State<PaginaTickets> createState() => _PaginaTicketsState();
}

class _PaginaTicketsState extends State<PaginaTickets> {
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
    final tickets = proveedor.reservas
        .where((r) => r.estado == EstadoReserva.completed)
        .toList()
      ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva));

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: EnvolturaResponsiva(
        child: proveedor.cargandoReservas
            ? const ListaEsqueleto()
            : tickets.isEmpty
                ? const EstadoVacio(
                    icono: Icons.receipt_long_outlined,
                    titulo: 'Sin tickets todavía',
                    subtitulo: 'Aquí aparecerá el historial de tus citas pagadas',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => EntradaAnimada(
                      index: i,
                      child: _TarjetaTicket(reserva: tickets[i]),
                    ),
                  ),
      ),
    );
  }
}

class _TarjetaTicket extends StatelessWidget {
  final Reserva reserva;
  const _TarjetaTicket({required this.reserva});

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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.nombreServicio ?? 'Servicio',
                          style: const TextStyle(
                              color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('$fechaTexto · ${r.horaInicio}',
                            style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                      ],
                    ),
                  ),
                  ChipEstado(etiqueta: r.estado.label, color: r.estado.color),
                ],
              ),
            ),
            const PerforacionTicket(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Atendido por',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(r.nombreEmpleado ?? '—',
                          style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total pagado',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        '\$${r.precioTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: context.colorPrimario, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
