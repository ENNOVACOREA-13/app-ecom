import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/service_provider.dart';
import 'package:prettycore/domain/models/service_model.dart';

ModeloServicio _servicio() => const ModeloServicio(
      id: 's1',
      nombre: 'Corte',
      descripcion: 'Corte clásico',
      duracionMin: 30,
      precio: 100,
      urlImagen: 'foto.png',
      estaActivo: true,
      iconoNombre: 'scissors',
      iconoColor: '#FF0000',
    );

void main() {
  group('aplicarActualizacionServicio', () {
    test('un cambio parcial solo toca los campos incluidos', () {
      final actualizado = aplicarActualizacionServicio(_servicio(), {'price': 150});
      expect(actualizado.precio, 150);
      expect(actualizado.nombre, 'Corte'); // sin cambios
      expect(actualizado.duracionMin, 30); // sin cambios
    });

    test('un mapa vacío no cambia nada', () {
      final original = _servicio();
      final actualizado = aplicarActualizacionServicio(original, const {});
      expect(actualizado.nombre, original.nombre);
      expect(actualizado.precio, original.precio);
      expect(actualizado.iconoNombre, original.iconoNombre);
    });

    test('un ícono explícitamente null en el mapa SÍ lo borra (a diferencia de un campo ausente)', () {
      final actualizado = aplicarActualizacionServicio(
        _servicio(),
        {'icon_name': null},
      );
      expect(actualizado.iconoNombre, isNull);
    });

    test('varios campos a la vez se aplican todos', () {
      final actualizado = aplicarActualizacionServicio(_servicio(), {
        'name': 'Corte + Barba',
        'price': 180,
        'is_active': false,
      });
      expect(actualizado.nombre, 'Corte + Barba');
      expect(actualizado.precio, 180);
      expect(actualizado.estaActivo, isFalse);
      expect(actualizado.descripcion, 'Corte clásico'); // no tocado, se conserva
    });
  });
}
