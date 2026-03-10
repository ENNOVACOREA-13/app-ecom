import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaReservasEmpleado extends StatefulWidget {
  const PaginaReservasEmpleado({super.key});

  @override
  State<PaginaReservasEmpleado> createState() => _PaginaReservasEmpleadoState();
}

class _PaginaReservasEmpleadoState extends State<PaginaReservasEmpleado> {
  EstadoReserva? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<ProveedorAuth>().perfil?.id;
      if (id != null) context.read<ProveedorReserva>().cargarReservasEmpleado(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();

    final filtradas = _filtro == null
        ? proveedor.reservas
        : proveedor.reservas.where((b) => b.estado == _filtro).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _ChipFiltro(label: 'Todas', selected: _filtro == null, onTap: () => setState(() => _filtro = null)),
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

          Expanded(
            child: proveedor.cargandoReservas
                ? const Center(child: CircularProgressIndicator())
                : filtradas.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.calendar_today_outlined,
                        titulo: 'Sin reservas',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          return _TarjetaReservaEmpleado(reserva: filtradas[i]);
                        },
                      ),
          ),
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
          color: selected ? kPrimary : kCard,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: kDivider, width: 0.5),
          boxShadow: selected
              ? [
                  BoxShadow(color: Color(0x664ECDC4), blurRadius: 8, offset: const Offset(0, 4)),
                ]
              : kNeumorphicShadowsSmall,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextSub,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TarjetaReservaEmpleado extends StatelessWidget {
  final Reserva reserva;
  const _TarjetaReservaEmpleado({required this.reserva});

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

  @override
  Widget build(BuildContext context) {
    final fechaTexto = DateFormat('EEE dd MMM', 'es_ES').format(reserva.fechaReserva);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: kNeumorphicShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reserva.nombreCliente ?? 'Cliente',
                  style: const TextStyle(color: kText, fontWeight: FontWeight.bold),
                ),
              ),
              ChipEstado(etiqueta: reserva.estado.label, color: _colorEstado(reserva.estado)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reserva.nombreServicio ?? 'Servicio',
            style: const TextStyle(color: kPrimary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 6),
              Text(fechaTexto, style: const TextStyle(color: kTextMuted, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_outlined, size: 14, color: kTextMuted),
              const SizedBox(width: 6),
              Text(
                '${reserva.horaInicio} – ${reserva.horaFin}',
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
          if (reserva.estado == EstadoReserva.confirmed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context
                    .read<ProveedorReserva>()
                    .actualizarEstado(reserva.id, EstadoReserva.completed),
                child: const Text('Marcar como completada'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
