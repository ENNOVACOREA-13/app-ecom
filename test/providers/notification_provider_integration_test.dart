import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/notification_provider.dart';
import 'package:prettycore/data/notification_repository.dart';
import 'package:prettycore/domain/models/app_notification.dart';

class MockRepositorioNotificaciones extends Mock implements RepositorioNotificaciones {}

NotificacionApp _notificacion({String id = 'n1', bool leida = false}) => NotificacionApp(
      id: id,
      titulo: 'Título',
      cuerpo: 'Cuerpo',
      tipo: 'general',
      leida: leida,
      creadaEn: DateTime(2026, 1, 1),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_notificacion());
  });

  group('iniciar', () {
    test('carga las notificaciones del usuario y se suscribe a nuevas', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1'))
          .thenAnswer((_) async => [_notificacion(id: 'a'), _notificacion(id: 'b', leida: true)]);
      when(() => repo.suscribirse(any(), any())).thenReturn(null);

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');

      expect(provider.notificaciones.length, 2);
      expect(provider.noLeidas, 1);
      verify(() => repo.suscribirse('u1', any())).called(1);
    });

    test('llamar iniciar dos veces con el mismo usuario no vuelve a cargar ni suscribir', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1')).thenAnswer((_) async => []);
      when(() => repo.suscribirse(any(), any())).thenReturn(null);

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');
      await provider.iniciar('u1');

      verify(() => repo.obtenerNotificaciones('u1')).called(1);
      verify(() => repo.suscribirse(any(), any())).called(1);
    });

    test('una notificación nueva por el canal realtime se agrega al frente de la lista', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1')).thenAnswer((_) async => []);
      void Function(NotificacionApp)? callbackCapturado;
      when(() => repo.suscribirse(any(), any())).thenAnswer((invocation) {
        callbackCapturado = invocation.positionalArguments[1] as void Function(NotificacionApp);
      });

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');
      callbackCapturado!(_notificacion(id: 'nueva'));

      expect(provider.notificaciones.first.id, 'nueva');
      expect(provider.noLeidas, 1);
    });
  });

  group('marcarLeida', () {
    test('actualiza el estado local y avisa al servidor', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1')).thenAnswer((_) async => [_notificacion(id: 'a')]);
      when(() => repo.suscribirse(any(), any())).thenReturn(null);
      when(() => repo.marcarLeida('a')).thenAnswer((_) async {});

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');
      expect(provider.noLeidas, 1);

      await provider.marcarLeida('a');

      expect(provider.noLeidas, 0);
      verify(() => repo.marcarLeida('a')).called(1);
    });

    test('marcar una ya leída no vuelve a llamar al servidor', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1'))
          .thenAnswer((_) async => [_notificacion(id: 'a', leida: true)]);
      when(() => repo.suscribirse(any(), any())).thenReturn(null);

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');
      await provider.marcarLeida('a');

      verifyNever(() => repo.marcarLeida(any()));
    });
  });

  group('detener', () {
    test('cancela la suscripción y limpia el estado', () async {
      final repo = MockRepositorioNotificaciones();
      when(() => repo.obtenerNotificaciones('u1')).thenAnswer((_) async => [_notificacion()]);
      when(() => repo.suscribirse(any(), any())).thenReturn(null);
      when(() => repo.cancelarSuscripcion()).thenReturn(null);

      final provider = ProveedorNotificaciones(repo: repo);
      await provider.iniciar('u1');
      provider.detener();

      expect(provider.notificaciones, isEmpty);
      verify(() => repo.cancelarSuscripcion()).called(1);
    });
  });
}
