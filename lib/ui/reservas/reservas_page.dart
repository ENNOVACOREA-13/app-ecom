import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/reservation_repository.dart';
import '../../data/employee_repository.dart';
import '../../domain/models/reservation.dart';
import '../../domain/models/profile.dart';
import '../../domain/app_context.dart';
import '../../domain/services/role_service.dart';
import '../theme/app_theme.dart';

class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});
  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  final _repo = RepoReservas();
  final _repoEmpleados = RepositorioEmpleado();
  Future<List<Reserva>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contexto = context.watch<ContextoApp>();
    final rol = contexto.rol;
    final empleadoId = contexto.empleadoId;

    _future ??= _cargarReservas(rol, empleadoId);
  }

  void _recargarReservas() {
    final contexto = context.read<ContextoApp>();
    setState(() {
      _future = _cargarReservas(contexto.rol, contexto.empleadoId);
    });
  }

  Future<List<Reserva>> _cargarReservas(String rol, String? empleadoId) async {
    // Admin: ve todas las reservas
    if (RoleService.esAdmin(rol)) {
      return await _repo.listarTodas();
    }
    // Empleado: solo ve las reservas asignadas a el/ella
    if (RoleService.esEmpleado(rol)) {
      return await _repo.misReservasEmpleado();
    }
    // Usuario normal: solo ve sus propias reservas
    return await _repo.misReservasUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Mis Reservas'),
      ),
      body: FutureBuilder<List<Reserva>>(
        future: _future,
        builder: (ctx, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = s.data ?? const <Reserva>[];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No tienes reservas',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agenda tu primera cita',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargarReservas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) => _ReservaCard(
                r: items[i],
                onCancelada: _recargarReservas,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _mostrarDialogoNuevaReserva(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaReserva(BuildContext context) async {
    final empleados = await _repoEmpleados.obtenerEmpleados();
    if (empleados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay barberos disponibles'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NuevaReservaSheet(
        empleados: empleados,
        repo: _repo,
      ),
    );

    if (resultado == true && mounted) {
      _recargarReservas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _NuevaReservaSheet extends StatefulWidget {
  final List<Perfil> empleados;
  final RepoReservas repo;

  const _NuevaReservaSheet({
    required this.empleados,
    required this.repo,
  });

  @override
  State<_NuevaReservaSheet> createState() => _NuevaReservaSheetState();
}

class _NuevaReservaSheetState extends State<_NuevaReservaSheet> {
  Perfil? _empleadoSeleccionado;
  String? _servicioSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 11, minute: 0);
  bool _guardando = false;

  final List<String> _servicios = [
    'Corte de cabello',
    'Corte + Barba',
    'Arreglo de barba',
    'Corte degradado',
    'Tinte de cabello',
    'Tratamiento capilar',
  ];

  // Horarios disponibles de 11am a 7pm
  List<TimeOfDay> get _horariosDisponibles {
    final horarios = <TimeOfDay>[];
    for (int hora = 11; hora < 19; hora++) {
      horarios.add(TimeOfDay(hour: hora, minute: 0));
      horarios.add(TimeOfDay(hour: hora, minute: 30));
    }
    return horarios;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agendar Cita',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seleccionar Barbero
                  const Text(
                    'Selecciona tu barbero',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.empleados.map((e) {
                      final selected = _empleadoSeleccionado?.id == e.id;
                      return GestureDetector(
                        onTap: () => setState(() => _empleadoSeleccionado = e),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: selected
                                    ? Colors.white24
                                    : AppColors.primary.withValues(alpha: 0.3),
                                child: Text(
                                  e.nombreCompleto.isNotEmpty ? e.nombreCompleto[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                e.nombreCompleto,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Seleccionar Servicio
                  const Text(
                    'Tipo de servicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _servicioSeleccionado,
                        hint: const Text(
                          'Selecciona un servicio',
                          style: TextStyle(color: Colors.white54),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white54),
                        items: _servicios.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _servicioSeleccionado = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Seleccionar Fecha
                  const Text(
                    'Fecha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es_MX')
                                .format(_fechaSeleccionada),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit, color: Colors.white38, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Seleccionar Hora
                  const Text(
                    'Hora (11:00 AM - 7:00 PM)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _horariosDisponibles.map((hora) {
                      final selected = _horaSeleccionada.hour == hora.hour &&
                          _horaSeleccionada.minute == hora.minute;
                      final horaStr =
                          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                      return GestureDetector(
                        onTap: () => setState(() => _horaSeleccionada = hora),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            horaStr,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Footer con boton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _puedeGuardar() && !_guardando
                      ? _guardarReserva
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmar Cita',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _puedeGuardar() {
    return _empleadoSeleccionado != null && _servicioSeleccionado != null;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _guardarReserva() async {
    if (!_puedeGuardar()) return;

    setState(() => _guardando = true);

    try {
      final fechaHora = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      await widget.repo.crearReserva(
        employeeId: _empleadoSeleccionado!.id,
        startsAt: fechaHora,
        service: _servicioSeleccionado!,
        appId: 'barber_app',
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva r;
  final VoidCallback onCancelada;

  const _ReservaCard({required this.r, required this.onCancelada});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es_MX');
    final timeFormat = DateFormat('HH:mm');

    Color estadoColor;
    IconData estadoIcon;
    switch (r.estado.toLowerCase()) {
      case 'confirmada':
        estadoColor = Colors.greenAccent;
        estadoIcon = Icons.check_circle;
        break;
      case 'pendiente':
        estadoColor = Colors.orangeAccent;
        estadoIcon = Icons.schedule;
        break;
      case 'cancelada':
        estadoColor = Colors.redAccent;
        estadoIcon = Icons.cancel;
        break;
      case 'completada':
        estadoColor = Colors.blueAccent;
        estadoIcon = Icons.done_all;
        break;
      default:
        estadoColor = Colors.blueAccent;
        estadoIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  r.estado.toUpperCase(),
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(r.inicio),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r.servicio,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${timeFormat.format(r.inicio)} - ${timeFormat.format(r.fin)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
