import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/service_icons.dart';
import '../common/app_widgets.dart';

class PaginaSeleccionarServicio extends StatefulWidget {
  const PaginaSeleccionarServicio({super.key});

  @override
  State<PaginaSeleccionarServicio> createState() => _PaginaSeleccionarServicioState();
}

class _PaginaSeleccionarServicioState extends State<PaginaSeleccionarServicio> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorServicio>().cargarServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedorServicio = context.watch<ProveedorServicio>();
    final reserva = context.watch<ProveedorReserva>();
    final seleccionados = reserva.serviciosSeleccionados;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: EnvolturaResponsiva(
        child: Stack(
        children: [
          proveedorServicio.cargando
              ? const Center(child: CircularProgressIndicator())
              : proveedorServicio.servicios.isEmpty
                  ? const EstadoVacio(
                      icono: Icons.design_services_outlined,
                      titulo: 'Sin servicios disponibles',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          16, 16, 16, seleccionados.isNotEmpty ? 96 : 16),
                      itemCount: proveedorServicio.servicios.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final s = proveedorServicio.servicios[i];
                        final estaSeleccionado =
                            seleccionados.any((sel) => sel.id == s.id);
                        return GestureDetector(
                          onTap: () {
                            context.read<ProveedorReserva>().seleccionarServicio(s);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: estaSeleccionado
                                  ? null
                                  : Border.all(color: const Color(0xFFE5E5EA), width: 1),
                              boxShadow: estaSeleccionado
                                  ? [
                                      BoxShadow(color: Color(0x444ECDC4), blurRadius: 12, offset: const Offset(0, 4)),
                                    ]
                                  : [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: colorDesdeHex(s.iconoColor) ?? context.colorPrimario,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(obtenerIconoServicio(s.iconoNombre),
                                    color: Colors.white),
                              ),
                              title: Text(s.nombre,
                                  style: const TextStyle(
                                      color: Color(0xFF1C1C1E),
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(s.etiquetaDuracion,
                                  style: const TextStyle(
                                      color: Color(0xFF8E8E93), fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '\$${s.precio.toStringAsFixed(0)}',
                                          style: TextStyle(
                                              color: context.colorPrimario,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  estaSeleccionado
                                      ? Icon(Icons.check_circle,
                                          color: context.colorPrimario, size: 24)
                                      : const Icon(Icons.radio_button_unchecked,
                                          color: Color(0xFF8E8E93), size: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

          // Barra inferior: visible cuando hay al menos 1 servicio seleccionado
          if (seleccionados.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reserva.servicioSeleccionado?.nombre ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '\$${reserva.totalPrecio.toStringAsFixed(0)} · ${reserva.totalDuracionMin}min',
                              style: const TextStyle(
                                  color: Color(0xFF8E8E93), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.push('/booking/slot'),
                        child: const Text('Continuar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
