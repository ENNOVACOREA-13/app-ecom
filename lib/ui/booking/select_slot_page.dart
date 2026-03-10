import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../domain/models/slot.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaSeleccionarTurno extends StatefulWidget {
  const PaginaSeleccionarTurno({super.key});

  @override
  State<PaginaSeleccionarTurno> createState() => _PaginaSeleccionarTurnoState();
}

class _PaginaSeleccionarTurnoState extends State<PaginaSeleccionarTurno> {
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final proveedor = context.read<ProveedorReserva>();
      proveedor.seleccionarFecha(_fechaSeleccionada);
      proveedor.cargarTurnos();
    });
  }

  Future<void> _elegirFecha() async {
    final fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimary),
        ),
        child: child!,
      ),
    );
    if (fechaElegida != null && mounted) {
      setState(() => _fechaSeleccionada = fechaElegida);
      final proveedor = context.read<ProveedorReserva>();
      proveedor.seleccionarFecha(fechaElegida);
      proveedor.cargarTurnos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();
    final fechaTexto = DateFormat('EEEE dd \'de\' MMMM', 'es_ES').format(_fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un horario'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      bottomNavigationBar: proveedor.turnoSeleccionado != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BotonPrincipal(
                  etiqueta: 'Confirmar reserva',
                  onPressed: () => context.push('/booking/confirm'),
                ),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen selección
          _BarraResumen(proveedor: proveedor),

          // Selector de fecha
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fechaTexto,
                    style: const TextStyle(
                        color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ),

          // Slots
          Expanded(
            child: proveedor.cargandoTurnos
                ? const Center(child: CircularProgressIndicator())
                : proveedor.turnos.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.access_time_outlined,
                        titulo: 'Sin horarios disponibles',
                        subtitulo: 'Prueba con otra fecha',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: proveedor.turnos.length,
                        itemBuilder: (context, i) {
                          final turno = proveedor.turnos[i];
                          final seleccionado = proveedor.turnoSeleccionado?.inicio == turno.inicio;
                          return GestureDetector(
                            onTap: () => proveedor.seleccionarTurno(turno),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: seleccionado ? kPrimary : kCard,
                                borderRadius: BorderRadius.circular(10),
                                border: seleccionado
                                    ? null
                                    : Border.all(color: kDivider, width: 0.5),
                                boxShadow: seleccionado
                                    ? [
                                        BoxShadow(color: Color(0x664ECDC4), blurRadius: 8, offset: const Offset(0, 4)),
                                      ]
                                    : kNeumorphicShadowsSmall,
                              ),
                              child: Text(
                                turno.inicio,
                                style: TextStyle(
                                  color: seleccionado ? Colors.white : kTextSub,
                                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BarraResumen extends StatelessWidget {
  final ProveedorReserva proveedor;
  const _BarraResumen({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          _chip(Icons.content_cut, proveedor.servicioSeleccionado?.nombre ?? '—'),
          const SizedBox(width: 12),
          _chip(Icons.person_outline, proveedor.empleadoSeleccionado?.nombreCompleto ?? '—'),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String etiqueta) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kTextSub),
        const SizedBox(width: 4),
        Text(etiqueta, style: const TextStyle(color: kTextSub, fontSize: 12)),
      ],
    );
  }
}
