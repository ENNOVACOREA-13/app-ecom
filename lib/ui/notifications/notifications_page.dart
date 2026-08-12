import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../../domain/models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../common/app_widgets.dart';

const Map<String, IconData> _kIconosPorTipo = {
  'booking_new': Icons.calendar_today_outlined,
  'booking_confirmed': Icons.check_circle_outline,
  'booking_cancelled': Icons.cancel_outlined,
  'booking_completed': Icons.content_cut,
  'order_new': Icons.shopping_bag_outlined,
};

class PaginaNotificaciones extends StatelessWidget {
  const PaginaNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorNotificaciones>();
    final notificaciones = prov.notificaciones;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (prov.noLeidas > 0)
            TextButton(
              onPressed: () => context.read<ProveedorNotificaciones>().marcarTodasLeidas(),
              child: Text('Marcar leídas',
                  style: TextStyle(color: context.colorPrimario, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProveedorNotificaciones>().cargar(),
          child: prov.cargando && notificaciones.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notificaciones.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EstadoVacio(
                          icono: Icons.notifications_none_rounded,
                          titulo: 'Sin notificaciones',
                          subtitulo: 'Aquí verás avisos de reservas y pedidos',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: notificaciones.length,
                      itemBuilder: (_, i) => EntradaAnimada(
                        index: i,
                        child: _FilaNotificacion(notificacion: notificaciones[i]),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _FilaNotificacion extends StatelessWidget {
  final NotificacionApp notificacion;
  const _FilaNotificacion({required this.notificacion});

  @override
  Widget build(BuildContext context) {
    final icono = _kIconosPorTipo[notificacion.tipo] ?? Icons.notifications_outlined;
    final fmt = DateFormat('dd MMM, HH:mm', 'es_ES');

    return GestureDetector(
      onTap: notificacion.leida
          ? null
          : () => context.read<ProveedorNotificaciones>().marcarLeida(notificacion.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: notificacion.leida ? Colors.white : context.colorPrimario.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notificacion.leida ? const Color(0xFFE5E5EA) : context.colorPrimario.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorPrimario.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: context.colorPrimario, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notificacion.titulo,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(notificacion.cuerpo,
                      style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(fmt.format(notificacion.creadaEn),
                      style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 10)),
                ],
              ),
            ),
            if (!notificacion.leida)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: context.colorPrimario,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
