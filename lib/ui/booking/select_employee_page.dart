import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/employee_repository.dart';
import '../../domain/models/profile.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaSeleccionarEmpleado extends StatefulWidget {
  const PaginaSeleccionarEmpleado({super.key});

  @override
  State<PaginaSeleccionarEmpleado> createState() => _PaginaSeleccionarEmpleadoState();
}

class _PaginaSeleccionarEmpleadoState extends State<PaginaSeleccionarEmpleado> {
  final _repo = RepositorioEmpleado();
  List<Perfil> _empleados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final reserva = context.read<ProveedorReserva>();
    final idServicio = reserva.servicioSeleccionado?.id;
    try {
      List<Perfil> lista = [];
      if (idServicio != null) {
        lista = await _repo.obtenerEmpleadosPorServicio(idServicio);
      }
      // Si no hay empleados asignados al servicio, mostrar todos los activos
      if (lista.isEmpty) {
        lista = await _repo.obtenerEmpleados();
      }
      setState(() {
        _empleados = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = context.watch<ProveedorReserva>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Servicios seleccionados
          if (reserva.serviciosSeleccionados.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.content_cut, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reserva.serviciosSeleccionados.length == 1
                          ? reserva.servicioSeleccionado!.nombre
                          : '${reserva.serviciosSeleccionados.length} servicios',
                      style: const TextStyle(color: kText, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    reserva.serviciosSeleccionados.length == 1
                        ? '${reserva.totalDuracionMin}min'
                        : '${reserva.totalDuracionMin}min total',
                    style: const TextStyle(color: kTextSub, fontSize: 12),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _empleados.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.people_outline,
                        titulo: 'Sin empleados disponibles',
                        subtitulo: 'Ningún empleado ofrece este servicio aún',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _empleados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final emp = _empleados[i];
                          return Container(
                            decoration: const BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              boxShadow: kNeumorphicShadowsSmall,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              leading: AvatarRed(url: emp.urlAvatar, nombre: emp.nombreCompleto, radio: 22),
                              title: Text(emp.nombreCompleto,
                                  style: const TextStyle(
                                      color: kText, fontWeight: FontWeight.w600)),
                              subtitle: emp.bio != null
                                  ? Text(emp.bio!,
                                      style: const TextStyle(color: kTextSub, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)
                                  : null,
                              trailing: const Icon(Icons.chevron_right, color: kTextSub),
                              onTap: () {
                                context.read<ProveedorReserva>().seleccionarEmpleado(emp);
                                context.push('/booking/slot');
                              },
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
