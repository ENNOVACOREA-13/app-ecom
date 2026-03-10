import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/booking_repository.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaTableroAdmin extends StatefulWidget {
  const PaginaTableroAdmin({super.key});

  @override
  State<PaginaTableroAdmin> createState() => _PaginaTableroAdminState();
}

class _PaginaTableroAdminState extends State<PaginaTableroAdmin> {
  final _repo = RepositorioReserva();
  List<Map<String, dynamic>> _estEmpleados = [];
  List<Map<String, dynamic>> _serviciosPopulares = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final resultados = await Future.wait([
        _repo.obtenerTodasEstadisticasEmpleados(),
        _repo.obtenerServiciosPopulares(),
      ]);
      setState(() {
        _estEmpleados = resultados[0] as List<Map<String, dynamic>>;
        _serviciosPopulares = resultados[1] as List<Map<String, dynamic>>;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;

    // Totales globales
    final totalCompletadas = _estEmpleados.fold<int>(
        0, (sum, e) => sum + ((e['total_completadas'] as int?) ?? 0));
    final totalIngresos = _estEmpleados.fold<double>(
        0, (sum, e) => sum + ((e['ingresos_totales'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${perfil?.nombreCompleto.split(' ').first ?? 'Admin'}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 24),

                    // Stats globales
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        TarjetaEstadistica(
                          etiqueta: 'Servicios completados',
                          valor: '$totalCompletadas',
                          icono: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        TarjetaEstadistica(
                          etiqueta: 'Ingresos totales',
                          valor: '\$${totalIngresos.toStringAsFixed(0)}',
                          icono: Icons.attach_money,
                          color: kPrimary,
                        ),
                        TarjetaEstadistica(
                          etiqueta: 'Empleados activos',
                          valor: '${_estEmpleados.length}',
                          icono: Icons.people_outline,
                          color: Colors.blue,
                        ),
                        TarjetaEstadistica(
                          etiqueta: 'Servicios populares',
                          valor: '${_serviciosPopulares.length}',
                          icono: Icons.trending_up,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Top servicios
                    if (_serviciosPopulares.isNotEmpty) ...[
                      const Text('Servicios más populares',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 12),
                      ..._serviciosPopulares.take(5).map((s) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              boxShadow: kNeumorphicShadowsSmall,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.content_cut, color: kPrimary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(s['name'] as String? ?? '',
                                      style: const TextStyle(color: kText)),
                                ),
                                Text(
                                  '${s['veces_reservado'] ?? 0} reservas',
                                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Stats por empleado
                    if (_estEmpleados.isNotEmpty) ...[
                      const Text('Rendimiento por empleado',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 12),
                      ..._estEmpleados.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              boxShadow: kNeumorphicShadowsSmall,
                            ),
                            child: Row(
                              children: [
                                AvatarRed(nombre: e['full_name'] as String?, radio: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['full_name'] as String? ?? '',
                                          style: const TextStyle(
                                              color: kText, fontWeight: FontWeight.w600)),
                                      Text(
                                        '${e['total_completadas'] ?? 0} completadas',
                                        style: const TextStyle(color: kTextMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${(e['ingresos_totales'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                      color: kPrimary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
