import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/commission_model.dart';

class RepositorioComision {
  final _client = Supabase.instance.client;

  // ── Configuraciones por servicio ──────────────────────────────

  Future<List<ConfigComision>> obtenerConfiguraciones() async {
    final datos = await _client.from('commission_configs').select();
    return (datos as List).map((e) => ConfigComision.fromMap(e)).toList();
  }

  Future<void> guardarConfiguracion(String servicioId, double monto) async {
    await _client.from('commission_configs').upsert({
      'service_id': servicioId,
      'amount': monto,
      'updated_at': DateTime.now().toIso8601String(),
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
    final dato = await _client
        .from('commission_settings')
        .select()
        .maybeSingle();
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
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Entradas de comisión (empleado) ──────────────────────────

  Future<List<EntradaComision>> obtenerEntradasEmpleado(
      String empleadoId, {DateTime? desde, DateTime? hasta}) async {
    var query = _client
        .from('commission_entries')
        .select()
        .eq('employee_id', empleadoId);
    if (desde != null) {
      query = query.gte('earned_at', desde.toIso8601String());
    }
    if (hasta != null) {
      query = query.lte('earned_at', hasta.toIso8601String());
    }
    final datos = await query.order('earned_at', ascending: false);
    return (datos as List).map((e) => EntradaComision.fromMap(e)).toList();
  }

  /// Entradas de la semana actual (sin corte asignado) para un empleado
  Future<List<EntradaComision>> obtenerEntradaSemanaActual(String empleadoId) async {
    final ahora = DateTime.now();
    final diasDesdeLunes = ahora.weekday - 1; // Monday=0
    final inicioSemana = DateTime(ahora.year, ahora.month, ahora.day - diasDesdeLunes);
    final datos = await _client
        .from('commission_entries')
        .select()
        .eq('employee_id', empleadoId)
        .gte('earned_at', inicioSemana.toIso8601String())
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

  /// Procesa el corte semanal para el rango dado
  Future<void> procesarCorte(DateTime inicioSemana, DateTime finSemana) async {
    final ini = '${inicioSemana.year}-${inicioSemana.month.toString().padLeft(2, '0')}-${inicioSemana.day.toString().padLeft(2, '0')}';
    final fin = '${finSemana.year}-${finSemana.month.toString().padLeft(2, '0')}-${finSemana.day.toString().padLeft(2, '0')}';
    await _client.rpc('process_commission_cut', params: {
      'p_week_start': ini,
      'p_week_end': fin,
    });
  }

  /// Resumen de comisiones de la semana actual por empleado (para admin)
  Future<List<Map<String, dynamic>>> obtenerResumenSemanaActual() async {
    final ahora = DateTime.now();
    final diasDesdeLunes = ahora.weekday - 1;
    final inicioSemana = DateTime(ahora.year, ahora.month, ahora.day - diasDesdeLunes);
    final datos = await _client
        .from('commission_entries')
        .select('employee_id, commission_amount, profiles(full_name)')
        .gte('earned_at', inicioSemana.toIso8601String())
        .isFilter('cut_id', null);
    // Agrupar por empleado
    final mapa = <String, Map<String, dynamic>>{};
    for (final e in datos as List) {
      final empId = e['employee_id'] as String;
      final nombre = (e['profiles'] as Map?)?['full_name'] as String?;
      final monto = (e['commission_amount'] as num).toDouble();
      if (!mapa.containsKey(empId)) {
        mapa[empId] = {'employee_id': empId, 'full_name': nombre, 'total': 0.0, 'count': 0};
      }
      mapa[empId]!['total'] = (mapa[empId]!['total'] as double) + monto;
      mapa[empId]!['count'] = (mapa[empId]!['count'] as int) + 1;
    }
    return mapa.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }
}
