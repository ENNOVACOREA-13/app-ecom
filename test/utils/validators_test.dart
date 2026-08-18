import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/utils/validators.dart';

void main() {
  group('esEmailValido', () {
    test('acepta emails con formato normal', () {
      expect(esEmailValido('persona@dominio.com'), isTrue);
      expect(esEmailValido('a.b+c@sub.dominio.mx'), isTrue);
    });

    test('rechaza strings sin @ o sin punto', () {
      expect(esEmailValido('sinarroba.com'), isFalse);
      expect(esEmailValido('sinpunto@dominio'), isFalse);
      expect(esEmailValido(''), isFalse);
    });

    // La validación actual solo revisa que existan '@' y '.' en cualquier
    // posición, así que acepta strings claramente inválidos como email real.
    // Este test documenta el hueco conocido, no lo avala — si algún día se
    // endurece esEmailValido, este test debe fallar y actualizarse a mano.
    test('hueco conocido: acepta formatos que no son un email real', () {
      expect(esEmailValido('@.'), isTrue);
      expect(esEmailValido('a@b.'), isTrue);
    });
  });
}
