import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/commission_model.dart';

void main() {
  group('AjustesComision.nombreDia', () {
    test('resuelve los límites del arreglo (0=Domingo, 6=Sábado)', () {
      const inicio = AjustesComision(id: 'a1', diaCierre: 0, horaCierre: 23, minutoCierre: 59);
      const fin = AjustesComision(id: 'a1', diaCierre: 6, horaCierre: 23, minutoCierre: 59);
      expect(inicio.nombreDia, 'Domingo');
      expect(fin.nombreDia, 'Sábado');
    });
  });

  group('AjustesComision.horaTexto', () {
    test('rellena con ceros a la izquierda', () {
      const ajuste = AjustesComision(id: 'a1', diaCierre: 1, horaCierre: 9, minutoCierre: 5);
      expect(ajuste.horaTexto, '09:05');
    });

    test('respeta horas y minutos de dos dígitos', () {
      const ajuste = AjustesComision(id: 'a1', diaCierre: 1, horaCierre: 23, minutoCierre: 59);
      expect(ajuste.horaTexto, '23:59');
    });
  });

  group('AjustesComision.fromMap', () {
    test('valores por defecto: cierre a las 23:59 del domingo', () {
      final ajuste = AjustesComision.fromMap(const {'id': 'a1'});
      expect(ajuste.diaCierre, 0);
      expect(ajuste.horaCierre, 23);
      expect(ajuste.minutoCierre, 59);
    });
  });

  group('CorteComision.estaPagado', () {
    test('true solo cuando estado es paid', () {
      final pagado = CorteComision.fromMap(_corteMap(estado: 'paid'));
      final pendiente = CorteComision.fromMap(_corteMap(estado: 'pending'));
      expect(pagado.estaPagado, isTrue);
      expect(pendiente.estaPagado, isFalse);
    });
  });
}

Map<String, dynamic> _corteMap({required String estado}) => {
      'id': 'c1',
      'employee_id': 'e1',
      'week_start': '2026-08-10T00:00:00.000Z',
      'week_end': '2026-08-16T23:59:59.000Z',
      'total_amount': 500,
      'status': estado,
      'created_at': '2026-08-17T00:00:00.000Z',
    };
