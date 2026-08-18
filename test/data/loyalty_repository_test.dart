import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/loyalty_repository.dart';
import 'package:prettycore/domain/models/loyalty.dart';

MovimientoLealtad _movimiento({String id = 'm1', double puntos = 10}) {
  return MovimientoLealtad(
    id: id,
    origen: 'ajuste_manual',
    puntos: puntos,
    creadoEl: DateTime(2026, 1, 1),
  );
}

void main() {
  group('sumaSaldo', () {
    test('lista vacía da saldo 0', () {
      expect(sumaSaldo(const []), 0);
    });

    test('suma puntos positivos y negativos (canjes restan saldo)', () {
      final movimientos = [
        _movimiento(puntos: 100),
        _movimiento(puntos: 50),
        _movimiento(puntos: -30), // canje
      ];
      expect(sumaSaldo(movimientos), 120);
    });

    test('cada movimiento cuenta exactamente una vez', () {
      final movimientos = List.generate(5, (i) => _movimiento(id: 'm$i', puntos: 10));
      expect(sumaSaldo(movimientos), 50);
    });
  });
}
