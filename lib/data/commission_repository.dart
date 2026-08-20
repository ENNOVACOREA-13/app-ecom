import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/commission_model.dart';

/// Agrupa filas crudas de `commission_entries` por empleado, sumando monto y
/// conteo, y ordena de mayor a menor total. Filas sin `employee_id` o
/// `commission_amount` válidos se ignoran en vez de reventar el resumen.
List<Map<String, dynamic>> agruparComisionesPorEmpleado(
    List<dynamic> filas) {
  final mapa = <String, Map<String, dynamic>>{};
  for (final e in filas) {
    final empId = e['employee_id'] as String?;
    final monto = (e['commission_amount'] as num?)?.toDouble();
    if (empId == null || monto == null) continue;
    final nombre = (e['profiles'] as Map?)?['full_name'] as String?;
    final entrada = mapa.putIfAbsent(
        empId,
        () => {
              'employee_id': empId,
              'full_name': nombre,
              'total': 0.0,
              'count': 0,
            });
    entrada['total'] = (entrada['total'] as double) + monto;
    entrada['count'] = (entrada['count'] as int) + 1;
  }
  return mapa.values.toList()
    ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
}

class RepositorioComision {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Configuraciones por servicio ──────────────────────────────

  Future<List<ConfigComision>> obtenerConfiguraciones() async {
    final datos = await _client.from('commission_configs').select();
    return (datos as List).map((e) => ConfigComision.fromMap(e)).toList();
  }

  Future<void> guardarConfiguracion(String servicioId, double monto) async {
    // tenant_id es NOT NULL sin default — sin mandarlo aquí, la PRIMERA vez
    // que se configura la comisión de un servicio (sin fila previa) truena
    // por la restricción de la columna antes de siquiera llegar a RLS.
    await _client.from('commission_configs').upsert({
      'service_id': servicioId,
      'tenant_id': kTenantIdActivo,
      'amount': monto,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'service_id');
  }

  Future<void> eliminarConfiguracion(String servicioId) async {
    await _client
        .from('commission_configs')
        .delete()
        .eq('service_id', servicioId);
  }

  // ── Ajustes de cierre semanal ─────────────────────────────────

  Future<AjustesComision?> obtenerAjustes() async {
    final dato =
        await _client.from('commission_settings').select().maybeSingle();
    if (dato == null) return null;
    return AjustesComision.fromMap(dato);
  }

  Future<void> guardarAjustes({
    required String id,
    required int diaCierre,
    required int horaCierre,
    required int minutoCierre,
  }) async {
    await _client.from('commission_settings').update({
      'cutoff_day': diaCierre,
      'cutoff_hour': horaCierre,
      'cutoff_minute': minutoCierre,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ── Entradas de comisión (empleado) ──────────────────────────

  Future<List<EntradaComision>> obtenerEntradasEmpleado(String empleadoId,
      {DateTime? desde, DateTime? hasta}) async {
    var query = _client
        .from('commission_entries')
        .select()
        .eq('employee_id', empleadoId);
    if (desde != null) {
      query = query.gte('earned_at', desde.toUtc().toIso8601String());
    }
    if (hasta != null) {
      query = query.lte('earned_at', hasta.toUtc().toIso8601String());
    }
    final datos = await query.order('earned_at', ascending: false);
    return (datos as List).map((e) => EntradaComision.fromMap(e)).toList();
  }

  /// Entradas pendientes de corte (cut_id null) para un empleado — sin
  /// importar cuándo se ganaron. Antes solo miraba desde el inicio de la
  /// semana actual, así que comisiones de semanas anteriores que nunca se
  /// cortaron desaparecían de la vista del empleado sin dejar rastro,
  /// aunque seguían sumando en el total de comisiones del negocio.
  Future<List<EntradaComision>> obtenerEntradasPendientes(
      String empleadoId) async {
    final datos = await _client
        .from('commission_entries')
        .select()
        .eq('employee_id', empleadoId)
        .isFilter('cut_id', null)
        .order('earned_at', ascending: false);
    return (datos as List).map((e) => EntradaComision.fromMap(e)).toList();
  }

  // ── Cortes de comisión ────────────────────────────────────────

  Future<List<CorteComision>> obtenerCortesEmpleado(String empleadoId) async {
    final datos = await _client
        .from('commission_cuts')
        .select('*, profiles(full_name)')
        .eq('employee_id', empleadoId)
        .order('week_start', ascending: false);
    return (datos as List).map((e) {
      final m = Map<String, dynamic>.from(e);
      m['full_name'] = (e['profiles'] as Map?)?['full_name'];
      return CorteComision.fromMap(m);
    }).toList();
  }

  Future<List<CorteComision>> obtenerTodosLosCortes() async {
    final datos = await _client
        .from('commission_cuts')
        .select('*, profiles(full_name)')
        .order('week_start', ascending: false);
    return (datos as List).map((e) {
      final m = Map<String, dynamic>.from(e);
      m['full_name'] = (e['profiles'] as Map?)?['full_name'];
      return CorteComision.fromMap(m);
    }).toList();
  }

  Future<void> marcarCortePagado(String corteId, {String? notas}) async {
    await _client.from('commission_cuts').update({
      'status': 'paid',
      if (notas != null) 'notes': notas,
    }).eq('id', corteId);
  }

  /// Procesa el corte de TODO lo pendiente (cut_id null) con earned_at
  /// hasta la fecha dada — no solo "esta semana", así nunca queda un
  /// residuo sin cortar por un corte que alguien se saltó.
  Future<void> procesarCorte(DateTime hasta) async {
    final fecha =
        '${hasta.year}-${hasta.month.toString().padLeft(2, '0')}-${hasta.day.toString().padLeft(2, '0')}';
    await _client.rpc('process_commission_cut', params: {'p_hasta': fecha});
  }

  /// Resumen de comisiones PENDIENTES por empleado (para admin) — todo lo
  /// que un corte se llevaría si se procesara ahora mismo, sin importar
  /// cuándo se ganó.
  Future<List<Map<String, dynamic>>> obtenerResumenPendiente() async {
    final datos = await _client
        .from('commission_entries')
        .select('employee_id, commission_amount, profiles(full_name)')
        .isFilter('cut_id', null);
    return agruparComisionesPorEmpleado(datos as List);
  }
}
