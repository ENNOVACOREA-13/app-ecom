import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/booking_provider.dart';
import 'package:prettycore/domain/models/service_model.dart';
import 'package:prettycore/domain/models/profile.dart';
import 'package:prettycore/domain/enums/user_role.dart';

ModeloServicio _servicio({String id = 's1', double precio = 100, int duracionMin = 30}) {
  return ModeloServicio(
    id: id,
    nombre: 'Servicio $id',
    duracionMin: duracionMin,
    precio: precio,
    estaActivo: true,
  );
}

void main() {
  group('totalPrecio / totalDuracionMin', () {
    test('son 0 sin servicio seleccionado', () {
      final provider = ProveedorReserva();
      expect(provider.totalPrecio, 0);
      expect(provider.totalDuracionMin, 0);
    });

    test('reflejan el servicio seleccionado', () {
      final provider = ProveedorReserva();
      provider.seleccionarServicio(_servicio(precio: 250, duracionMin: 45));
      expect(provider.totalPrecio, 250);
      expect(provider.totalDuracionMin, 45);
    });
  });

  group('seleccionarServicio', () {
    test('tocar el mismo servicio ya seleccionado lo deselecciona', () {
      final provider = ProveedorReserva();
      final servicio = _servicio();
      provider.seleccionarServicio(servicio);
      expect(provider.servicioSeleccionado, isNotNull);
      provider.seleccionarServicio(servicio);
      expect(provider.servicioSeleccionado, isNull);
      expect(provider.totalPrecio, 0);
    });

    test('seleccionar un servicio nuevo reemplaza al anterior (solo 1 por reserva)', () {
      final provider = ProveedorReserva();
      provider.seleccionarServicio(_servicio(id: 's1', precio: 100));
      provider.seleccionarServicio(_servicio(id: 's2', precio: 200));
      expect(provider.serviciosSeleccionados.length, 1);
      expect(provider.servicioSeleccionado!.id, 's2');
      expect(provider.totalPrecio, 200);
    });

    test('cambiar de servicio limpia empleado y turno ya elegidos', () {
      final provider = ProveedorReserva();
      provider.seleccionarServicio(_servicio(id: 's1'));
      provider.seleccionarEmpleado(Perfil(
        id: 'e1',
        nombreCompleto: 'Empleado Uno',
        rol: RolUsuario.employee,
        estaActivo: true,
        creadoEn: DateTime(2026, 1, 1),
      ));
      expect(provider.empleadoSeleccionado, isNotNull);
      provider.seleccionarServicio(_servicio(id: 's2'));
      expect(provider.empleadoSeleccionado, isNull);
      expect(provider.turnoSeleccionado, isNull);
    });
  });

  group('seleccionarFecha', () {
    test('cambiar de fecha limpia el turno y la lista de turnos cargados', () {
      final provider = ProveedorReserva();
      provider.seleccionarFecha(DateTime(2026, 8, 20));
      expect(provider.fechaSeleccionada, DateTime(2026, 8, 20));
      expect(provider.turnoSeleccionado, isNull);
      expect(provider.turnos, isEmpty);
    });
  });

  group('reiniciarFlujo', () {
    test('limpia selección de servicio, empleado, fecha y turno', () {
      final provider = ProveedorReserva();
      provider.seleccionarServicio(_servicio());
      provider.seleccionarFecha(DateTime(2026, 8, 20));
      provider.reiniciarFlujo();
      expect(provider.servicioSeleccionado, isNull);
      expect(provider.fechaSeleccionada, isNull);
      expect(provider.totalPrecio, 0);
    });
  });
}
