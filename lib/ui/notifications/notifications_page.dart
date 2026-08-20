import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/enums/user_role.dart';
import '../../data/booking_repository.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/app_widgets.dart';
import '../common/skeleton.dart';
import '../client/booking_detail_page.dart';
import '../admin/all_bookings_page.dart';
import '../admin/admin_orders_page.dart';
import '../employee/employee_bookings_page.dart';

const Map<String, IconData> _kIconosPorTipo = {
  'booking_new': Icons.calendar_today_outlined,
  'booking_confirmed': Icons.check_circle_outline,
  'booking_cancelled': Icons.cancel_outlined,
  'booking_completed': Icons.content_cut,
  'booking_cancel_requested': Icons.hourglass_top_rounded,
  'booking_cancel_rejected': Icons.block_outlined,
  'order_new': Icons.shopping_bag_outlined,
};

class PaginaNotificaciones extends StatefulWidget {
  const PaginaNotificaciones({super.key});

  @override
  State<PaginaNotificaciones> createState() => _PaginaNotificacionesState();
}

class _PaginaNotificacionesState extends State<PaginaNotificaciones> {
  @override
  void initState() {
    super.initState();
    // La lista en el provider puede estar obsoleta (se llenó una sola vez al
    // iniciar sesión, y de ahí depende de tiempo real) — al abrir la pantalla
    // siempre se refresca, para no depender de que ningún evento se haya
    // perdido mientras el usuario no tenía la app abierta o conectada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorNotificaciones>().cargar();
    });
  }

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
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProveedorNotificaciones>().cargar(),
          child: prov.cargando && notificaciones.isEmpty
              ? const ListaEsqueleto()
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
      ),
    );
  }
}

class _FilaNotificacion extends StatelessWidget {
  final NotificacionApp notificacion;
  const _FilaNotificacion({required this.notificacion});

  Future<void> _manejarTap(BuildContext context) async {
    if (!notificacion.leida) {
      context.read<ProveedorNotificaciones>().marcarLeida(notificacion.id);
    }

    final relatedId = notificacion.relatedId;
    final rol = context.read<ProveedorAuth>().perfil?.rol;
    if (relatedId == null || rol == null) return;

    if (notificacion.tipo.startsWith('booking_')) {
      if (rol == RolUsuario.client) {
        final reserva = await RepositorioReserva().obtenerReservaPorId(relatedId);
        if (reserva != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaginaDetalleReserva(reserva: reserva)),
          );
        }
      } else if (rol == RolUsuario.employee) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaginaReservasEmpleado()),
        );
      } else {
        // admin, super_admin, sysadmin
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaginaTodasReservas()),
        );
      }
    } else if (notificacion.tipo == 'order_new') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaginaPedidosAdmin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final icono = _kIconosPorTipo[notificacion.tipo] ?? Icons.notifications_outlined;
    final fmt = DateFormat('dd MMM, HH:mm', 'es_ES');

    return GestureDetector(
      onTap: () => _manejarTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: notificacion.leida
              ? kColorSobreFondo.withOpacity(0.05)
              : context.colorPrimario.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notificacion.leida
                ? kColorSobreFondo.withOpacity(0.12)
                : context.colorPrimario.withOpacity(0.35),
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
                      style: TextStyle(
                          color: kColorSobreFondo,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(notificacion.cuerpo,
                      style: TextStyle(color: kColorSobreFondo.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(fmt.format(notificacion.creadaEn),
                      style: TextStyle(color: kColorSobreFondo.withOpacity(0.5), fontSize: 10)),
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
