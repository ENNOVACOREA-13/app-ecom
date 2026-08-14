import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaDetalleReserva extends StatefulWidget {
  final Reserva reserva;
  const PaginaDetalleReserva({super.key, required this.reserva});

  @override
  State<PaginaDetalleReserva> createState() => _PaginaDetalleReservaState();
}

class _PaginaDetalleReservaState extends State<PaginaDetalleReserva> {
  final _claveTarjeta = GlobalKey();
  Reserva get reserva => widget.reserva;

  Future<void> _compartirQr(BuildContext context) async {
    try {
      final boundary = _claveTarjeta.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final imagen = await boundary.toImage(pixelRatio: 3);
      final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(reserva.fechaReserva);

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'reserva_qr.png', mimeType: 'image/png')],
        text:
            'Código QR de mi cita: ${reserva.nombreServicio ?? 'Servicio'} el $fechaTexto a las ${reserva.horaInicio}. Muéstralo al llegar.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo compartir: $e')),
        );
      }
    }
  }

  Future<void> _cancelar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Seguro que quieres cancelar esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar reserva', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      final perfil = context.read<ProveedorAuth>().perfil!;
      await context.read<ProveedorReserva>().cancelarReserva(
            reserva.id,
            perfil.id,
            motivo: 'Cancelada por el cliente',
          );
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _solicitarCancelacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar cancelación'),
        content: const Text(
            'Esta reserva ya está confirmada. Se enviará una solicitud de cancelación al negocio para que la apruebe. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Solicitar cancelación', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await context.read<ProveedorReserva>().solicitarCancelacion(reserva.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada, en espera de aprobación')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    final esTicketPagado = r.estado == EstadoReserva.completed;
    final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(r.fechaReserva);
    final fechaPagoTexto =
        r.fechaPago != null ? DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(r.fechaPago!) : null;
    final perfil = context.watch<ProveedorAuth>().perfil;
    final email = Supabase.instance.client.auth.currentUser?.email;

    final tamano = MediaQuery.of(context).size;
    final esEscritorio = tamano.width >= kAnchoEscritorio;
    final margenExtra = esEscritorio ? margenLateralEscritorio(tamano.width) : 0.0;

    // ── Círculo decorativo del encabezado ──────────────────────────
    // En escritorio el ancho de pantalla puede ser enorme, así que la
    // fórmula original (basada solo en el ancho) dejaba las esquinas
    // sin cubrir (por eso no se veía la flecha). Aquí calculamos un
    // círculo garantizado a cubrir todo el ancho + margen de seguridad,
    // y más grande/visible ("que abarque más") en escritorio.
    final double diametroCirculo;
    final double topCirculo;
    if (esEscritorio) {
      const alturaVisible = 240.0;
      const margenSeguridad = 100.0;
      final mitadCobertura = (tamano.width + margenSeguridad * 2) / 2;
      diametroCirculo =
          alturaVisible + (mitadCobertura * mitadCobertura) / alturaVisible;
      topCirculo = -(diametroCirculo - alturaVisible);
    } else {
      diametroCirculo = tamano.width * 1.15;
      topCirculo = (tamano.height * 0.4) - diametroCirculo;
    }
    final leftCirculo = (tamano.width - diametroCirculo) / 2;

    return Scaffold(
      backgroundColor: kBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        title: Text(esTicketPagado ? 'Ticket de pago' : 'Detalles de reserva'),
        actions: [
          if (r.estado == EstadoReserva.confirmed || esTicketPagado)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartir QR',
              onPressed: () => _compartirQr(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: topCirculo,
            left: leftCirculo,
            child: Container(
              width: diametroCirculo,
              height: diametroCirculo,
              decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20 + margenExtra,
              kToolbarHeight + (esEscritorio ? 150 : 20), 20 + margenExtra, 20),
          child: EnvolturaFormularioResponsivo(
            anchoMaximo: 480,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _claveTarjeta,
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.nombreServicio ?? 'Servicio',
                                      style: const TextStyle(
                                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 17),
                                    ),
                                  ),
                                  ChipEstado(etiqueta: r.estado.label, color: r.estado.color),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(fechaTexto,
                                    style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1, color: Color(0xFFE5E5EA)),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _CampoDetalle(
                                        etiqueta: 'Servicio', valor: r.nombreServicio ?? '—'),
                                  ),
                                  Expanded(
                                    child: _CampoDetalle(
                                        etiqueta: 'Empleado', valor: r.nombreEmpleado ?? '—'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CampoDetalle(etiqueta: 'Fecha', valor: fechaTexto),
                                  ),
                                  Expanded(
                                    child: _CampoDetalle(
                                        etiqueta: 'Horario', valor: '${r.horaInicio} – ${r.horaFin}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CampoDetalle(
                                        etiqueta: 'Total',
                                        valor: '\$${r.precioTotal.toStringAsFixed(0)}',
                                        destacado: true),
                                  ),
                                  Expanded(
                                    child: _CampoDetalle(etiqueta: 'Estado', valor: r.estado.label),
                                  ),
                                ],
                              ),
                              if (esTicketPagado && fechaPagoTexto != null) ...[
                                const SizedBox(height: 18),
                                _CampoDetalle(
                                    etiqueta: 'Fecha de pago', valor: fechaPagoTexto, destacado: true),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        if (esTicketPagado) ...[
                          const PerforacionTicket(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Datos del cliente',
                                    style: TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CampoDetalle(
                                          etiqueta: 'Nombre',
                                          valor: perfil?.nombreCompleto.isNotEmpty == true
                                              ? perfil!.nombreCompleto
                                              : '—'),
                                    ),
                                    Expanded(
                                      child: _CampoDetalle(
                                          etiqueta: 'Teléfono',
                                          valor: perfil?.telefono?.isNotEmpty == true
                                              ? perfil!.telefono!
                                              : '—'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _CampoDetalle(etiqueta: 'Email', valor: email ?? '—'),
                              ],
                            ),
                          ),
                          const PerforacionTicket(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: 'reserva:${r.id}',
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Código de verificación de tu ticket de pago',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ] else if (r.estado == EstadoReserva.confirmed) ...[
                          const PerforacionTicket(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: 'reserva:${r.id}',
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Muestra este código al llegar a tu cita',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ] else if (r.estado == EstadoReserva.pending) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'El código QR estará disponible cuando el negocio confirme tu reserva',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

              if (r.puedeCancelarDirecto) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => _cancelar(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar reserva'),
                ),
              ],
              if (r.puedeSolicitarCancelacion) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => _solicitarCancelacion(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Solicitar cancelación'),
                ),
              ],
              if (r.estado == EstadoReserva.confirmed && r.cancelacionSolicitada) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Cancelación solicitada, esperando aprobación',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
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

class _CampoDetalle extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;
  const _CampoDetalle({required this.etiqueta, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: destacado ? context.colorPrimario : const Color(0xFF1C1C1E),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

