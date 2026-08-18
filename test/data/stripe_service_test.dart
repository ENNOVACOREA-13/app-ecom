import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/stripe_service.dart';

void main() {
  group('centavosDesdeMonto', () {
    test('montos "limpios" convierten sin sorpresas', () {
      expect(centavosDesdeMonto(10.10), 1010);
      expect(centavosDesdeMonto(100.05), 10005);
      expect(centavosDesdeMonto(33.33), 3333);
    });

    // Regresión: 19.99 * 100 da 1998.9999999999998 por imprecisión de
    // punto flotante. toInt() truncaba a 1998 (cobraba $19.98 en vez de
    // $19.99) — un cobro de menos real y silencioso en cualquier precio
    // terminado en .99, el terminado de precio más común del negocio.
    test('no cobra de menos en precios terminados en .99', () {
      expect(centavosDesdeMonto(19.99), 1999);
      expect(centavosDesdeMonto(9.99), 999);
      expect(centavosDesdeMonto(149.99), 14999);
    });

    test('monto 0 da 0 centavos', () {
      expect(centavosDesdeMonto(0), 0);
    });
  });
}
