import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/notification_provider.dart';

void main() {
  group('ProveedorNotificaciones', () {
    test('arranca sin notificaciones y con noLeidas en 0', () {
      final provider = ProveedorNotificaciones();
      expect(provider.notificaciones, isEmpty);
      expect(provider.noLeidas, 0);
      expect(provider.cargando, isFalse);
    });

    test('marcarLeida/marcarTodasLeidas sobre una lista vacía no truena', () async {
      final provider = ProveedorNotificaciones();
      await provider.marcarLeida('id-inexistente');
      await provider.marcarTodasLeidas();
      expect(provider.noLeidas, 0);
    });

    test('detener limpia el estado', () {
      final provider = ProveedorNotificaciones();
      provider.detener();
      expect(provider.notificaciones, isEmpty);
      expect(provider.noLeidas, 0);
    });
  });
}
