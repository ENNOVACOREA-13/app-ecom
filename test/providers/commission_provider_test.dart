import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/commission_provider.dart';
import 'package:prettycore/domain/models/commission_model.dart';

EntradaComision _entrada({String id = 'x1', double monto = 50}) {
  return EntradaComision(
    id: id,
    empleadoId: 'e1',
    reservaId: 'r1',
    nombreServicio: 'Corte',
    precioServicio: 200,
    monto: monto,
    ganadorEl: DateTime(2026, 8, 18),
  );
}

void main() {
  group('totalPendienteEmpleado / serviciosPendientesEmpleado', () {
    test('0 y 0 sin entradas cargadas', () {
      final provider = ProveedorComision();
      expect(provider.totalPendienteEmpleado, 0);
      expect(provider.serviciosPendientesEmpleado, 0);
    });

    test('suma el monto de cada entrada pendiente', () {
      final provider = ProveedorComision();
      provider.entradasPendientes = [
        _entrada(id: 'a', monto: 50),
        _entrada(id: 'b', monto: 30),
        _entrada(id: 'c', monto: 20),
      ];
      expect(provider.totalPendienteEmpleado, 100);
      expect(provider.serviciosPendientesEmpleado, 3);
    });
  });

  group('montoPorServicio', () {
    test('0 si el servicio no tiene configuración de comisión', () {
      final provider = ProveedorComision();
      expect(provider.montoPorServicio('servicio-sin-config'), 0);
    });

    test('devuelve el monto configurado para el servicio', () {
      final provider = ProveedorComision();
      provider.configuraciones = [
        const ConfigComision(id: 'c1', servicioId: 's1', monto: 40),
        const ConfigComision(id: 'c2', servicioId: 's2', monto: 60),
      ];
      expect(provider.montoPorServicio('s2'), 60);
      expect(provider.montoPorServicio('s1'), 40);
    });
  });
}
