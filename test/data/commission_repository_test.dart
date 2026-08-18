import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/commission_repository.dart';

void main() {
  group('agruparComisionesPorEmpleado', () {
    test('suma monto y cuenta correctamente por empleado, sin perder ni duplicar entradas', () {
      final filas = [
        {'employee_id': 'e1', 'commission_amount': 50, 'profiles': {'full_name': 'Ana'}},
        {'employee_id': 'e1', 'commission_amount': 30, 'profiles': {'full_name': 'Ana'}},
        {'employee_id': 'e2', 'commission_amount': 20, 'profiles': {'full_name': 'Beto'}},
      ];
      final resumen = agruparComisionesPorEmpleado(filas);

      final ana = resumen.firstWhere((r) => r['employee_id'] == 'e1');
      final beto = resumen.firstWhere((r) => r['employee_id'] == 'e2');
      expect(ana['total'], 80.0);
      expect(ana['count'], 2);
      expect(beto['total'], 20.0);
      expect(beto['count'], 1);
      expect(resumen.length, 2);
    });

    test('ordena de mayor a menor total', () {
      final filas = [
        {'employee_id': 'e1', 'commission_amount': 10},
        {'employee_id': 'e2', 'commission_amount': 100},
        {'employee_id': 'e3', 'commission_amount': 50},
      ];
      final resumen = agruparComisionesPorEmpleado(filas);
      expect(resumen.map((r) => r['employee_id']), ['e2', 'e3', 'e1']);
    });

    test('lista vacía devuelve resumen vacío', () {
      expect(agruparComisionesPorEmpleado(const []), isEmpty);
    });

    test('ignora filas sin employee_id o commission_amount en vez de reventar', () {
      final filas = [
        {'employee_id': 'e1', 'commission_amount': 40},
        {'employee_id': null, 'commission_amount': 999},
        {'employee_id': 'e2', 'commission_amount': null},
      ];
      final resumen = agruparComisionesPorEmpleado(filas);
      expect(resumen.length, 1);
      expect(resumen.first['employee_id'], 'e1');
      expect(resumen.first['total'], 40.0);
    });
  });
}
