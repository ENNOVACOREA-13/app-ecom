import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/utils/date_utils.dart';

void main() {
  group('esFechaPasada', () {
    final hoy = DateTime(2026, 8, 18);

    test('una fecha de ayer es pasada', () {
      expect(esFechaPasada(DateTime(2026, 8, 17), ahora: hoy), isTrue);
    });

    test('hoy mismo NO es pasada (se puede reservar el mismo día)', () {
      expect(esFechaPasada(DateTime(2026, 8, 18), ahora: hoy), isFalse);
    });

    test('una fecha futura no es pasada', () {
      expect(esFechaPasada(DateTime(2026, 8, 19), ahora: hoy), isFalse);
    });

    test('ignora la hora, solo compara año/mes/día', () {
      final hoyConHora = DateTime(2026, 8, 18, 23, 59);
      final ahoraTemprano = DateTime(2026, 8, 18, 0, 1);
      expect(esFechaPasada(hoyConHora, ahora: ahoraTemprano), isFalse);
    });
  });

  group('formatearFechaISO', () {
    test('rellena mes y día con ceros a la izquierda', () {
      expect(formatearFechaISO(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatearFechaISO(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('inicioDeSemana', () {
    test('un lunes devuelve el mismo día', () {
      final lunes = DateTime(2026, 8, 17); // lunes
      expect(inicioDeSemana(lunes), DateTime(2026, 8, 17));
    });

    test('un domingo devuelve el lunes anterior (6 días atrás)', () {
      final domingo = DateTime(2026, 8, 23); // domingo
      expect(inicioDeSemana(domingo), DateTime(2026, 8, 17));
    });

    test('un miércoles devuelve el lunes de esa semana', () {
      final miercoles = DateTime(2026, 8, 19);
      expect(inicioDeSemana(miercoles), DateTime(2026, 8, 17));
    });
  });
}
