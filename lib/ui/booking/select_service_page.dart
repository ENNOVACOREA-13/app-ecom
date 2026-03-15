import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../core/theme/app_theme.dart';
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
      body: Stack(
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
                              color: kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: estaSeleccionado
                                  ? null
                                  : Border.all(color: kDivider, width: 1),
                              boxShadow: estaSeleccionado
                                  ? [
                                      BoxShadow(color: Color(0x444ECDC4), blurRadius: 12, offset: const Offset(0, 4)),
                                    ]
                                  : kNeumorphicShadowsSmall,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: estaSeleccionado
                                      ? kPrimaryLight
                                      : kCardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: kNeumorphicShadowsInset,
                                ),
                                child: const Icon(Icons.content_cut,
                                    color: Colors.white),
                              ),
                              title: Text(s.nombre,
                                  style: const TextStyle(
                                      color: kText,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(s.etiquetaDuracion,
                                  style: const TextStyle(
                                      color: kTextSub, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '\$${s.precio.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: kPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  estaSeleccionado
                                      ? const Icon(Icons.check_circle,
                                          color: kPrimary, size: 24)
                                      : const Icon(Icons.radio_button_unchecked,
                                          color: kTextSub, size: 24),
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
                decoration: const BoxDecoration(
                  color: kCard,
                  boxShadow: kNeumorphicShadowsSmall,
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
                              '${seleccionados.length} servicio${seleccionados.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: kText,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '\$${reserva.totalPrecio.toStringAsFixed(0)} · ${reserva.totalDuracionMin}min',
                              style: const TextStyle(
                                  color: kTextSub, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.push('/booking/employee'),
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
    );
  }
}
