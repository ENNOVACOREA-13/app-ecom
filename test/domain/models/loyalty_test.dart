import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/loyalty.dart';

void main() {
  group('ConfigLealtad.puntosPorMonto', () {
    test('redondea siempre hacia abajo (no se fabrican puntos por redondeo)', () {
      const config = ConfigLealtad(
        activo: true,
        nombrePrograma: 'Puntos',
        montoPorPunto: 100,
        puntosPorPesoCanje: 10,
        ganaPorReservas: true,
        ganaPorPedidos: true,
      );
      expect(config.puntosPorMonto(250), 2); // 2.5 -> 2, no 3
      expect(config.puntosPorMonto(99), 0);
      expect(config.puntosPorMonto(100), 1);
      expect(config.puntosPorMonto(0), 0);
    });
  });

  group('ConfigLealtad.valorEnPesos', () {
    test('convierte puntos a pesos usando la tasa de canje', () {
      const config = ConfigLealtad(
        activo: true,
        nombrePrograma: 'Puntos',
        montoPorPunto: 100,
        puntosPorPesoCanje: 10,
        ganaPorReservas: true,
        ganaPorPedidos: true,
      );
      expect(config.valorEnPesos(100), 10);
      expect(config.valorEnPesos(0), 0);
    });
  });

  group('ConfigLealtad.fromMap', () {
    test('aplica valores por defecto seguros cuando faltan campos', () {
      final config = ConfigLealtad.fromMap(const {});
      expect(config.activo, isTrue);
      expect(config.montoPorPunto, 100);
      expect(config.puntosPorPesoCanje, 10);
      expect(config.ganaPorReservas, isTrue);
      expect(config.ganaPorPedidos, isTrue);
    });

    test('respeta los valores explícitos del mapa', () {
      final config = ConfigLealtad.fromMap(const {
        'activo': false,
        'nombre_programa': 'VIP',
        'monto_por_punto': 50,
        'puntos_por_peso_canje': 5,
        'gana_por_reservas': false,
        'gana_por_pedidos': false,
      });
      expect(config.activo, isFalse);
      expect(config.nombrePrograma, 'VIP');
      expect(config.montoPorPunto, 50);
      expect(config.puntosPorPesoCanje, 5);
    });
  });

  group('MovimientoLealtad.fromMap', () {
    test('parsea correctamente un movimiento', () {
      final movimiento = MovimientoLealtad.fromMap({
        'id': 'm1',
        'origen': 'pedido',
        'origen_id': 'o1',
        'puntos': 12,
        'descripcion': 'Compra',
        'created_at': '2026-08-01T10:00:00.000Z',
      });
      expect(movimiento.puntos, 12.0);
      expect(movimiento.origen, 'pedido');
      expect(movimiento.creadoEl, DateTime.parse('2026-08-01T10:00:00.000Z'));
    });
  });
}
