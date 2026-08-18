import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/enums/order_status.dart';

void main() {
  group('EstadoPedidoX.fromString', () {
    test('mapea cada valor conocido de la BD', () {
      expect(EstadoPedidoX.fromString('confirmed'), EstadoPedido.confirmed);
      expect(EstadoPedidoX.fromString('ready'), EstadoPedido.ready);
      expect(EstadoPedidoX.fromString('delivered'), EstadoPedido.delivered);
      expect(EstadoPedidoX.fromString('cancelled'), EstadoPedido.cancelled);
    });

    test('un valor desconocido o vacío cae en pending, no revienta', () {
      expect(EstadoPedidoX.fromString('valor_raro'), EstadoPedido.pending);
      expect(EstadoPedidoX.fromString(''), EstadoPedido.pending);
    });
  });

  test('toDbString hace round-trip con fromString', () {
    for (final estado in EstadoPedido.values) {
      expect(EstadoPedidoX.fromString(estado.toDbString()), estado);
    }
  });
}
