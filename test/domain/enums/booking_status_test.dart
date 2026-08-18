import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/enums/booking_status.dart';

void main() {
  group('EstadoReserva.fromString', () {
    test('mapea cada valor conocido de la BD', () {
      expect(EstadoReserva.fromString('confirmed'), EstadoReserva.confirmed);
      expect(EstadoReserva.fromString('completed'), EstadoReserva.completed);
      expect(EstadoReserva.fromString('cancelled'), EstadoReserva.cancelled);
    });

    test('un valor desconocido o vacío cae en pending, no revienta', () {
      expect(EstadoReserva.fromString('valor_raro'), EstadoReserva.pending);
      expect(EstadoReserva.fromString(''), EstadoReserva.pending);
    });
  });

  test('toDbString hace round-trip con fromString', () {
    for (final estado in EstadoReserva.values) {
      expect(EstadoReserva.fromString(estado.toDbString()), estado);
    }
  });
}
