import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/booking_repository.dart';

void main() {
  group('RepositorioReserva — rechazo de fechas pasadas', () {
    // Estas dos llamadas fallan antes de tocar Supabase (el guard corre
    // primero), así que no hace falta inicializar el cliente para probarlas.
    final ayer = DateTime.now().subtract(const Duration(days: 1));

    test('obtenerTurnosDisponibles lanza DATE_IN_PAST para una fecha pasada', () async {
      final repo = RepositorioReserva();
      await expectLater(
        repo.obtenerTurnosDisponibles(
          idEmpleado: 'e1',
          fecha: ayer,
          duracionMin: 30,
        ),
        throwsA(predicate((e) => e.toString().contains('DATE_IN_PAST'))),
      );
    });

    test('crearReserva lanza DATE_IN_PAST para una fecha pasada', () async {
      final repo = RepositorioReserva();
      await expectLater(
        repo.crearReserva(
          idCliente: 'c1',
          idEmpleado: 'e1',
          idServicio: 's1',
          fecha: ayer,
          horaInicio: '10:00',
        ),
        throwsA(predicate((e) => e.toString().contains('DATE_IN_PAST'))),
      );
    });
  });
}
