import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/employee_repository.dart';
import '../../domain/models/profile.dart';
import '../../providers/booking_provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaSeleccionarTurno extends StatefulWidget {
  const PaginaSeleccionarTurno({super.key});

  @override
  State<PaginaSeleccionarTurno> createState() => _PaginaSeleccionarTurnoState();
}

class _PaginaSeleccionarTurnoState extends State<PaginaSeleccionarTurno> {
  final _repoEmpleado = RepositorioEmpleado();
  static final DateTime _hoy = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  static final DateTime _fechaMaxima = _hoy.add(const Duration(days: 60));

  late DateTime _fechaSeleccionada;
  late DateTime _inicioSemana;
  List<Perfil> _empleados = [];
  bool _cargandoEmpleados = true;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = _hoy.add(const Duration(days: 1));
    _inicioSemana = _lunesDe(_fechaSeleccionada);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEmpleados());
  }

  static DateTime _lunesDe(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  Future<void> _cargarEmpleados() async {
    final reserva = context.read<ProveedorReserva>();
    final idServicio = reserva.servicioSeleccionado?.id;
    try {
      List<Perfil> lista = [];
      if (idServicio != null) {
        lista = await _repoEmpleado.obtenerEmpleadosPorServicio(idServicio);
      }
      if (lista.isEmpty) {
        lista = await _repoEmpleado.obtenerEmpleados();
      }
      if (!mounted) return;
      setState(() {
        _empleados = lista;
        _cargandoEmpleados = false;
      });
      if (lista.isNotEmpty && reserva.empleadoSeleccionado == null) {
        reserva.seleccionarEmpleado(lista.first);
        reserva.seleccionarFecha(_fechaSeleccionada);
        reserva.cargarTurnos();
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoEmpleados = false);
    }
  }

  void _elegirFecha(DateTime dia) {
    if (dia.isBefore(_hoy) || dia.isAfter(_fechaMaxima)) return;
    setState(() => _fechaSeleccionada = dia);
    final reserva = context.read<ProveedorReserva>();
    reserva.seleccionarFecha(dia);
    if (reserva.empleadoSeleccionado != null) reserva.cargarTurnos();
  }

  void _cambiarSemana(int deltaDias) {
    final nuevoInicio = _inicioSemana.add(Duration(days: deltaDias));
    if (nuevoInicio.add(const Duration(days: 6)).isBefore(_hoy)) return;
    if (nuevoInicio.isAfter(_fechaMaxima)) return;
    setState(() => _inicioSemana = nuevoInicio);
  }

  void _elegirEmpleado(Perfil emp) {
    final reserva = context.read<ProveedorReserva>();
    if (reserva.empleadoSeleccionado?.id == emp.id) return;
    reserva.seleccionarEmpleado(emp);
    reserva.cargarTurnos();
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();
    final diasSemana = List.generate(7, (i) => _inicioSemana.add(Duration(days: i)));
    final tituloMes = DateFormat('MMMM yyyy', 'es_ES').format(_inicioSemana);
    final tituloMesCap = tituloMes.isEmpty
        ? tituloMes
        : tituloMes[0].toUpperCase() + tituloMes.substring(1);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Reservar cita'),
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
      body: EnvolturaResponsiva(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BarraResumen(proveedor: proveedor),

            // ── Selector de semana ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _cambiarSemana(-7),
                  ),
                  Text(tituloMesCap,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _cambiarSemana(7),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: diasSemana.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final dia = diasSemana[i];
                  final deshabilitado = dia.isBefore(_hoy) || dia.isAfter(_fechaMaxima);
                  final seleccionado = !deshabilitado &&
                      dia.year == _fechaSeleccionada.year &&
                      dia.month == _fechaSeleccionada.month &&
                      dia.day == _fechaSeleccionada.day;
                  return GestureDetector(
                    onTap: deshabilitado ? null : () => _elegirFecha(dia),
                    child: Container(
                      width: 44,
                      decoration: BoxDecoration(
                        color: seleccionado ? context.colorPrimario : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E', 'es_ES').format(dia).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: deshabilitado
                                  ? const Color(0xFFC7C7CC)
                                  : seleccionado
                                      ? Colors.white70
                                      : const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dia.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: deshabilitado
                                  ? const Color(0xFFC7C7CC)
                                  : seleccionado
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Horarios disponibles ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('HORARIOS DISPONIBLES',
                  style: TextStyle(
                      color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: proveedor.cargandoTurnos
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : proveedor.turnos.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EstadoVacio(
                            icono: Icons.access_time_outlined,
                            titulo: 'Sin horarios disponibles',
                            subtitulo: 'Prueba con otra fecha o especialista',
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: proveedor.turnos.length,
                          itemBuilder: (context, i) {
                            final turno = proveedor.turnos[i];
                            final seleccionado = proveedor.turnoSeleccionado?.inicio == turno.inicio;
                            return EntradaAnimada(
                              index: i,
                              child: TarjetaPresionable(
                                onTap: () => proveedor.seleccionarTurno(turno),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: seleccionado ? context.colorPrimario : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    turno.inicio,
                                    style: TextStyle(
                                      color: seleccionado ? Colors.white : const Color(0xFF3C3C43),
                                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 20),

            // ── Especialista ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('ELIGE ESPECIALISTA',
                  style: TextStyle(
                      color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            SizedBox(
              height: 92,
              child: _cargandoEmpleados
                  ? const Center(child: CircularProgressIndicator())
                  : _empleados.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Sin especialistas disponibles',
                              style: TextStyle(color: kTextMuted)),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _empleados.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, i) {
                            final emp = _empleados[i];
                            final seleccionado = proveedor.empleadoSeleccionado?.id == emp.id;
                            return TarjetaPresionable(
                              onTap: () => _elegirEmpleado(emp),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: seleccionado ? context.colorPrimario : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: AvatarRed(
                                        url: emp.urlAvatar, nombre: emp.nombreCompleto, radio: 26),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 64,
                                    child: Text(
                                      emp.nombreCompleto.split(' ').first,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                                        color: seleccionado
                                            ? context.colorPrimario
                                            : const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _chip(Icons.content_cut, proveedor.servicioSeleccionado?.nombre ?? '—'),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String etiqueta) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6E6E73)),
        const SizedBox(width: 4),
        Text(etiqueta, style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
      ],
    );
  }
}
