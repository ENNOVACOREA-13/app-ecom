import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/booking_repository.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaTableroEmpleado extends StatefulWidget {
  const PaginaTableroEmpleado({super.key});

  @override
  State<PaginaTableroEmpleado> createState() => _PaginaTableroEmpleadoState();
}

class _PaginaTableroEmpleadoState extends State<PaginaTableroEmpleado> {
  final _repo = RepositorioReserva();
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = context.read<ProveedorAuth>().perfil?.id;
    if (id == null) return;
    try {
      final estadisticas = await _repo.obtenerEstadisticasEmpleado(id);
      setState(() {
        _estadisticas = estadisticas;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Panel')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryLight, kCard],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: kNeumorphicShadows,
                    ),
                    child: Row(
                      children: [
                        AvatarRed(url: perfil?.urlAvatar, nombre: perfil?.nombreCompleto, radio: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfil?.nombreCompleto ?? '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: kText),
                              ),
                              const Text('Empleado', style: TextStyle(color: kTextSub)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Estadísticas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      TarjetaEstadistica(
                        etiqueta: 'Completadas',
                        valor: '${_estadisticas['total_completadas'] ?? 0}',
                        icono: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Pendientes',
                        valor: '${_estadisticas['total_pendientes'] ?? 0}',
                        icono: Icons.hourglass_empty_outlined,
                        color: Colors.orange,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Canceladas',
                        valor: '${_estadisticas['total_canceladas'] ?? 0}',
                        icono: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      TarjetaEstadistica(
                        etiqueta: 'Ingresos',
                        valor: '\$${(_estadisticas['ingresos_totales'] ?? 0).toStringAsFixed(0)}',
                        icono: Icons.attach_money,
                        color: kPrimary,
                      ),
                    ],
                  ),

                  if (_estadisticas['rating_promedio'] != null) ...[
                    const SizedBox(height: 24),
                    TarjetaSeccion(
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_estadisticas['rating_promedio']}',
                                style: const TextStyle(
                                    color: kText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_estadisticas['total_reviews'] ?? 0} reseñas',
                                style: const TextStyle(color: kTextSub, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
