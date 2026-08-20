import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/toast.dart';

class PaginaEscanearQR extends StatefulWidget {
  const PaginaEscanearQR({super.key});

  @override
  State<PaginaEscanearQR> createState() => _PaginaEscanearQRState();
}

class _PaginaEscanearQRState extends State<PaginaEscanearQR> {
  final _controlador = MobileScannerController();
  bool _procesando = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture captura) async {
    if (_procesando) return;
    final valor = captura.barcodes.firstOrNull?.rawValue;
    if (valor == null || !valor.startsWith('reserva:')) return;

    final id = valor.substring('reserva:'.length);
    setState(() => _procesando = true);
    await _controlador.stop();
    if (!mounted) return;

    final reserva = await context.read<ProveedorReserva>().obtenerReservaPorId(id);

    if (!mounted) return;

    if (reserva == null) {
      await _mostrarError('Código no válido', 'No se encontró esa reserva.');
    } else if (reserva.estado != EstadoReserva.confirmed) {
      await _mostrarError(
        'No se puede marcar como pagada',
        'Esta reserva está "${reserva.estado.label}". Solo se puede escanear cuando está Confirmada.',
      );
    } else {
      await _confirmarPago(reserva);
    }

    if (!mounted) return;
    setState(() => _procesando = false);
    await _controlador.start();
  }

  Future<void> _mostrarError(String titulo, String mensaje) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo)),
        ]),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Future<void> _confirmarPago(Reserva reserva) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reserva.nombreServicio ?? 'Servicio',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Cliente: ${reserva.nombreCliente ?? '—'}'),
            Text('Empleado: ${reserva.nombreEmpleado ?? '—'}'),
            Text('${reserva.horaInicio} – ${reserva.horaFin}'),
            const SizedBox(height: 8),
            Text('\$${reserva.precioTotal.toStringAsFixed(0)}',
                style: TextStyle(color: context.colorPrimario, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34C759)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Marcar como pagada', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<ProveedorReserva>().actualizarEstado(reserva.id, EstadoReserva.completed);
      if (mounted) {
        mostrarToast(context, 'Reserva marcada como pagada', tipo: TipoToast.exito);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Escanear código QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controlador.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controlador, onDetect: _onDetect),
          if (_procesando)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta al código QR de la reserva del cliente',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
