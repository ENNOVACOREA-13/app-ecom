import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/booking_provider.dart';
import 'package:prettycore/data/booking_repository.dart';
import 'package:prettycore/domain/models/booking.dart';
import 'package:prettycore/domain/models/service_model.dart';
import 'package:prettycore/domain/models/profile.dart';
import 'package:prettycore/domain/models/slot.dart';
import 'package:prettycore/domain/enums/booking_status.dart';
import 'package:prettycore/domain/enums/user_role.dart';

class MockRepositorioReserva extends Mock implements RepositorioReserva {}

ModeloServicio _servicio() => const ModeloServicio(
      id: 's1',
      nombre: 'Corte',
      duracionMin: 30,
      precio: 100,
      estaActivo: true,
    );

Perfil _empleado() => Perfil(
      id: 'e1',
      nombreCompleto: 'Empleado',
      rol: RolUsuario.employee,
      estaActivo: true,
      creadoEn: DateTime(2026, 1, 1),
    );

Reserva _reservaFalsa() => Reserva(
      id: 'r1',
      idCliente: 'c1',
      idEmpleado: 'e1',
      idServicio: 's1',
      fechaReserva: DateTime(2026, 8, 20),
      horaInicio: '10:00',
      horaFin: '10:30',
      estado: EstadoReserva.pending,
      precioTotal: 100,
      creadoEn: DateTime(2026, 8, 18),
    );

/// Deja al provider listo justo antes de crearReserva: con servicio,
/// empleado, fecha y turno ya seleccionados (los 4 que exige el guard).
ProveedorReserva _providerListoParaReservar(RepositorioReserva repo) {
  final provider = ProveedorReserva(repo: repo);
  provider.seleccionarServicio(_servicio());
  provider.seleccionarEmpleado(_empleado());
  provider.seleccionarFecha(DateTime(2026, 8, 20));
  provider.seleccionarTurno(const Turno(inicio: '10:00', fin: '10:30'));
  return provider;
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  group('crearReserva', () {
    test('éxito: llama al repo con los datos seleccionados y reinicia el flujo', () async {
      final repo = MockRepositorioReserva();
      when(() => repo.crearReserva(
            idCliente: any(named: 'idCliente'),
            idEmpleado: any(named: 'idEmpleado'),
            idServicio: any(named: 'idServicio'),
            fecha: any(named: 'fecha'),
            horaInicio: any(named: 'horaInicio'),
            notas: any(named: 'notas'),
            idsExtras: any(named: 'idsExtras'),
          )).thenAnswer((_) async => _reservaFalsa());

      final provider = _providerListoParaReservar(repo);
      final ok = await provider.crearReserva('c1');

      expect(ok, isTrue);
      expect(provider.error, isNull);
      expect(provider.servicioSeleccionado, isNull, reason: 'crearReserva reinicia el flujo al terminar');
      verify(() => repo.crearReserva(
            idCliente: 'c1',
            idEmpleado: 'e1',
            idServicio: 's1',
            fecha: DateTime(2026, 8, 20),
            horaInicio: '10:00',
            notas: null,
            idsExtras: const [],
          )).called(1);
    });

    test('conflicto de horario: el error del repo llega mapeado al usuario', () async {
      final repo = MockRepositorioReserva();
      when(() => repo.crearReserva(
            idCliente: any(named: 'idCliente'),
            idEmpleado: any(named: 'idEmpleado'),
            idServicio: any(named: 'idServicio'),
            fecha: any(named: 'fecha'),
            horaInicio: any(named: 'horaInicio'),
            notas: any(named: 'notas'),
            idsExtras: any(named: 'idsExtras'),
          )).thenThrow(Exception('BOOKING_CONFLICT'));

      final provider = _providerListoParaReservar(repo);
      final ok = await provider.crearReserva('c1');

      expect(ok, isFalse);
      expect(provider.error, 'Ese horario ya no está disponible. Elige otro.');
      // A diferencia del éxito, el flujo NO se reinicia: el usuario debe
      // poder elegir otro turno sin rehacer toda la selección.
      expect(provider.servicioSeleccionado, isNotNull);
      expect(provider.creando, isFalse);
    });
  });

  group('cargarTurnos', () {
    test('propaga la lista de turnos del repo', () async {
      final repo = MockRepositorioReserva();
      when(() => repo.obtenerTurnosDisponibles(
            idEmpleado: any(named: 'idEmpleado'),
            fecha: any(named: 'fecha'),
            duracionMin: any(named: 'duracionMin'),
          )).thenAnswer((_) async => [
            const Turno(inicio: '10:00', fin: '10:30'),
            const Turno(inicio: '11:00', fin: '11:30'),
          ]);

      final provider = ProveedorReserva(repo: repo);
      provider.seleccionarServicio(_servicio());
      provider.seleccionarEmpleado(_empleado());
      provider.seleccionarFecha(DateTime(2026, 8, 20));

      await provider.cargarTurnos();

      expect(provider.turnos.length, 2);
      expect(provider.cargandoTurnos, isFalse);
    });

    test('sin empleado/fecha/servicio seleccionados no llama al repo', () async {
      final repo = MockRepositorioReserva();
      final provider = ProveedorReserva(repo: repo);

      await provider.cargarTurnos();

      verifyNever(() => repo.obtenerTurnosDisponibles(
            idEmpleado: any(named: 'idEmpleado'),
            fecha: any(named: 'fecha'),
            duracionMin: any(named: 'duracionMin'),
          ));
    });
  });
}
