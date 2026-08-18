import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/booking_provider.dart';
import 'package:prettycore/providers/order_provider.dart';
import 'package:prettycore/providers/product_provider.dart';

void main() {
  group('mapearErrorReserva', () {
    test('conflicto de horario da mensaje específico', () {
      expect(mapearErrorReserva('Exception: BOOKING_CONFLICT'),
          'Ese horario ya no está disponible. Elige otro.');
    });

    test('fecha pasada da mensaje específico', () {
      expect(mapearErrorReserva('Exception: DATE_IN_PAST'),
          'No puedes reservar en una fecha pasada.');
    });

    test('un error desconocido no expone detalles internos del servidor', () {
      final mensaje = mapearErrorReserva('PostgrestException: relation "bookings" violates constraint xyz123');
      expect(mensaje, 'Ocurrió un error inesperado. Intenta de nuevo.');
      expect(mensaje.contains('bookings'), isFalse);
    });

    // Regresión: TimeoutException/SocketException reales de Dart se
    // stringifican con mayúscula ("TimeoutException...", "SocketException:
    // ...") y el check original ('timeout'/'network'/'socket' en minúsculas)
    // nunca los detectaba — el usuario siempre veía el mensaje genérico en
    // vez de "Sin conexión a internet"/"tardó demasiado".
    test('detecta un SocketException real sin conexión', () {
      final e = const SocketException('Connection refused');
      expect(mapearErrorReserva(e.toString()), 'Sin conexión a internet.');
    });

    test('detecta un TimeoutException real', () {
      final e = TimeoutException('Future not completed', const Duration(seconds: 4));
      expect(mapearErrorReserva(e.toString()), 'La solicitud tardó demasiado. Intenta de nuevo.');
    });
  });

  group('mapearErrorPedido', () {
    test('stock insuficiente da mensaje específico', () {
      expect(mapearErrorPedido('Exception: INSUFFICIENT_STOCK'),
          'Uno de los productos ya no tiene stock suficiente. Revisa tu carrito.');
    });

    test('carrito vacío da mensaje específico', () {
      expect(mapearErrorPedido('Exception: EMPTY_CART'), 'Tu carrito está vacío.');
    });

    test('detecta un SocketException real sin conexión', () {
      final e = const SocketException('network unreachable');
      expect(mapearErrorPedido(e.toString()), 'Sin conexión a internet.');
    });

    test('un error desconocido no expone detalles internos del servidor', () {
      final mensaje = mapearErrorPedido('PostgrestException: column "xyz" does not exist');
      expect(mensaje, 'Ocurrió un error al procesar tu pedido. Intenta de nuevo.');
    });
  });

  group('mapearErrorProducto', () {
    test('sin permiso da mensaje específico', () {
      expect(mapearErrorProducto('new row violates row-level security policy'),
          'No tienes permiso para realizar esta acción.');
    });

    test('detecta un TimeoutException real', () {
      final e = TimeoutException('Future not completed', const Duration(seconds: 4));
      expect(mapearErrorProducto(e.toString()), 'La solicitud tardó demasiado. Intenta de nuevo.');
    });
  });
}
