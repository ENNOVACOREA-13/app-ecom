import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaConfirmarReserva extends StatelessWidget {
  const PaginaConfirmarReserva({super.key});

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();
    final perfil = context.watch<ProveedorAuth>().perfil;

    final servicios = proveedor.serviciosSeleccionados;
    final empleado = proveedor.empleadoSeleccionado;
    final fecha = proveedor.fechaSeleccionada;
    final turno = proveedor.turnoSeleccionado;

    if (servicios.isEmpty || empleado == null || fecha == null || turno == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmar')),
        body: const Center(child: Text('Datos incompletos', style: TextStyle(color: Color(0xFF1C1C1E)))),
      );
    }

    final fechaTexto = DateFormat('EEEE dd \'de\' MMMM yyyy', 'es_ES').format(fecha);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar reserva'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BotonPrincipal(
            etiqueta: 'Confirmar y reservar',
            cargando: proveedor.creando,
            onPressed: () async {
              final exito = await proveedor.crearReserva(perfil!.id);
              if (exito && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Reserva creada exitosamente!'),
                  ),
                );
                context.go('/');
              } else if (context.mounted && proveedor.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(proveedor.error!)),
                );
              }
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de tu reserva',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 24),

            TarjetaSeccion(
              child: Column(
                children: [
                  // Fila(s) de servicios
                  if (servicios.length == 1) ...[
                    _Fila(Icons.design_services_outlined, 'Servicio', servicios.first.nombre),
                    const Divider(height: 20),
                    _Fila(Icons.timer_outlined, 'Duración', servicios.first.etiquetaDuracion),
                  ] else ...[
                    for (int i = 0; i < servicios.length; i++) ...[
                      _Fila(Icons.design_services_outlined,
                          i == 0 ? 'Servicios' : '', servicios[i].nombre),
                      const Divider(height: 20),
                    ],
                    _Fila(Icons.timer_outlined, 'Duración total',
                        '${proveedor.totalDuracionMin}min'),
                  ],
                  const Divider(height: 20),
                  _Fila(Icons.person_outline, 'Empleado', empleado.nombreCompleto),
                  const Divider(height: 20),
                  _Fila(Icons.calendar_today_outlined, 'Fecha', fechaTexto),
                  const Divider(height: 20),
                  _Fila(Icons.access_time_outlined, 'Horario',
                      '${turno.inicio} – ${turno.fin}'),
                  const Divider(height: 20),
                  _Fila(
                    Icons.attach_money,
                    'Total',
                    '\$${proveedor.totalPrecio.toStringAsFixed(0)}',
                    colorValor: kPrimary,
                    negrita: true,
                  ),
                ],
              ),
            ),

            if (proveedor.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(proveedor.error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;
  final bool negrita;

  const _Fila(this.icono, this.etiqueta, this.valor,
      {this.colorValor, this.negrita = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: kTextSub),
        const SizedBox(width: 12),
        Text(etiqueta, style: const TextStyle(color: kTextSub)),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            color: colorValor ?? kText,
            fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
            fontSize: negrita ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
