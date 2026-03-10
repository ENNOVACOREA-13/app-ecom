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
      appBar: AppBar(title: const Text('Mis Reservas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking/service'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: proveedor.cargandoReservas
          ? const Center(child: CircularProgressIndicator())
          : proveedor.reservas.isEmpty
              ? const EstadoVacio(
                  icono: Icons.calendar_today_outlined,
                  titulo: 'Sin reservas',
                  subtitulo: 'Crea tu primera reserva',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: proveedor.reservas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return _TarjetaReserva(reserva: proveedor.reservas[i]);
                  },
                ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  final Reserva reserva;

  const _TarjetaReserva({required this.reserva});

  Color _colorEstado(EstadoReserva s) {
    switch (s) {
      case EstadoReserva.pending:
        return Colors.orange;
      case EstadoReserva.confirmed:
        return Colors.blue;
      case EstadoReserva.completed:
        return Colors.green;
      case EstadoReserva.cancelled:
        return Colors.red;
    }
  }

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
            reserva.id,
            perfil.id,
            motivo: 'Cancelada por el cliente',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto = DateFormat('EEE dd MMM', 'es_ES').format(reserva.fechaReserva);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: kNeumorphicShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reserva.nombreServicio ?? 'Servicio',
                  style: const TextStyle(
                      color: kText, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ChipEstado(
                etiqueta: reserva.estado.label,
                color: _colorEstado(reserva.estado),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 15, color: kTextSub),
              const SizedBox(width: 6),
              Text(reserva.nombreEmpleado ?? '—', style: const TextStyle(color: kTextSub, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 15, color: kTextSub),
              const SizedBox(width: 6),
              Text(fechaTexto, style: const TextStyle(color: kTextSub, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 15, color: kTextSub),
              const SizedBox(width: 6),
              Text(
                '${reserva.horaInicio} – ${reserva.horaFin}',
                style: const TextStyle(color: kTextSub, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '\$${reserva.precioTotal.toStringAsFixed(0)}',
                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (reserva.puedeCancelar) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelar(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kDivider),
                  foregroundColor: kTextSub,
                ),
                child: const Text('Cancelar reserva'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
