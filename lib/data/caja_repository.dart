import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/caja_model.dart';

class RepositorioCaja {
  SupabaseClient get _client => Supabase.instance.client;

  /// Resumen en vivo del periodo actual (desde el último corte, o desde
  /// siempre si nunca se ha hecho uno) — no guarda nada, es solo lectura.
  Future<ResumenPeriodo> obtenerResumenActual() async {
    final filas = await _client.rpc('obtener_resumen_periodo_actual') as List;
    return ResumenPeriodo.fromMap(filas.first as Map<String, dynamic>);
  }

  /// Igual que arriba, pero para el propio empleado (auth.uid() del lado
  /// del servidor, nunca un id que mande el cliente).
  Future<ResumenPeriodoEmpleado> obtenerResumenActualEmpleado() async {
    final filas =
        await _client.rpc('obtener_resumen_periodo_actual_empleado') as List;
    return ResumenPeriodoEmpleado.fromMap(filas.first as Map<String, dynamic>);
  }

  /// Genera un corte real: guarda el snapshot del periodo actual como
  /// historial y hace que el periodo siguiente arranque en 0. No borra ni
  /// modifica ningún dato real (reservas, pedidos, comisiones, compras).
  Future<String> generarCorte() async {
    return await _client.rpc('generar_corte_caja') as String;
  }

  Future<List<CorteCaja>> obtenerCortes() async {
    final datos = await _client
        .from('caja_cuts')
        .select()
        .order('created_at', ascending: false);
    return (datos as List)
        .map((e) => CorteCaja.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmpleadoCorte>> obtenerDetalleEmpleadosCorte(String corteId) async {
    final datos = await _client
        .from('caja_cut_employee_stats')
        .select()
        .eq('cut_id', corteId)
        .order('ingresos', ascending: false);
    return (datos as List)
        .map((e) => EmpleadoCorte.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
