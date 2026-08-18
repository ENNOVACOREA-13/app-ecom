import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/booking.dart';
import 'package:prettycore/domain/enums/booking_status.dart';

Reserva _reserva({
  EstadoReserva estado = EstadoReserva.pending,
  bool cancelacionSolicitada = false,
}) {
  return Reserva(
    id: 'r1',
    idCliente: 'c1',
    idEmpleado: 'e1',
    idServicio: 's1',
    fechaReserva: DateTime(2026, 8, 20),
    horaInicio: '10:00',
    horaFin: '10:30',
    estado: estado,
    precioTotal: 100,
    creadoEn: DateTime(2026, 8, 18),
    cancelacionSolicitada: cancelacionSolicitada,
  );
}

void main() {
  group('puedeCancelarDirecto', () {
    test('true solo cuando está pending', () {
      expect(_reserva(estado: EstadoReserva.pending).puedeCancelarDirecto, isTrue);
      expect(_reserva(estado: EstadoReserva.confirmed).puedeCancelarDirecto, isFalse);
      expect(_reserva(estado: EstadoReserva.completed).puedeCancelarDirecto, isFalse);
      expect(_reserva(estado: EstadoReserva.cancelled).puedeCancelarDirecto, isFalse);
    });
  });

  group('puedeSolicitarCancelacion', () {
    test('true solo cuando está confirmed y sin solicitud previa', () {
      expect(
        _reserva(estado: EstadoReserva.confirmed, cancelacionSolicitada: false)
            .puedeSolicitarCancelacion,
        isTrue,
      );
    });

    test('false si ya hay una solicitud de cancelación en curso (evita duplicarla)', () {
      expect(
        _reserva(estado: EstadoReserva.confirmed, cancelacionSolicitada: true)
            .puedeSolicitarCancelacion,
        isFalse,
      );
    });

    test('false para cualquier estado que no sea confirmed', () {
      for (final estado in [
        EstadoReserva.pending,
        EstadoReserva.completed,
        EstadoReserva.cancelled,
      ]) {
        expect(_reserva(estado: estado).puedeSolicitarCancelacion, isFalse,
            reason: '$estado no debería permitir solicitar cancelación');
      }
    });
  });

  group('Reserva.fromMap', () {
    test('parsea correctamente los campos joined y recorta la hora a HH:mm', () {
      final reserva = Reserva.fromMap({
        'id': 'r1',
        'client_id': 'c1',
        'employee_id': 'e1',
        'service_id': 's1',
        'booking_date': '2026-08-20',
        'start_time': '10:00:00',
        'end_time': '10:30:00',
        'status': 'confirmed',
        'total_price': 250,
        'created_at': '2026-08-18T00:00:00.000Z',
        'client_name': 'Juan',
      });
      expect(reserva.horaInicio, '10:00');
      expect(reserva.horaFin, '10:30');
      expect(reserva.estado, EstadoReserva.confirmed);
      expect(reserva.nombreCliente, 'Juan');
    });

    test('ids ausentes no truenan, quedan como string vacío', () {
      final reserva = Reserva.fromMap({
        'id': 'r1',
        'booking_date': '2026-08-20',
        'start_time': '10:00:00',
        'end_time': '10:30:00',
        'total_price': 0,
      });
      expect(reserva.idCliente, '');
      expect(reserva.idEmpleado, '');
      expect(reserva.estado, EstadoReserva.pending);
    });
  });
}
