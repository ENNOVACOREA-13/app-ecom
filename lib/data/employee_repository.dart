import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/profile.dart';
import '../domain/enums/user_role.dart';
import '../utils/date_utils.dart';

class RepositorioEmpleado {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Perfil>> obtenerEmpleados() async {
    final datos = await _client
        .from('profiles_public')
        .select()
        .eq('role', 'employee')
        .eq('is_active', true)
        .order('full_name');
    return (datos as List).map((e) => Perfil.fromMap(e)).toList();
  }

  Future<List<Perfil>> obtenerTodosLosUsuarios() async {
    final datos = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (datos as List).map((e) => Perfil.fromMap(e)).toList();
  }

  // Empleados que realizan un servicio específico
  Future<List<Perfil>> obtenerEmpleadosPorServicio(String idServicio) async {
    final vinculos = await _client
        .from('employee_services')
        .select('employee_id')
        .eq('service_id', idServicio);
    final ids = (vinculos as List).map((e) => e['employee_id'] as String).toList();
    if (ids.isEmpty) return [];

    final datos = await _client
        .from('profiles_public')
        .select()
        .inFilter('id', ids);
    return (datos as List)
        .map((e) => Perfil.fromMap(e as Map<String, dynamic>))
        .where((p) => p.estaActivo)
        .toList();
  }

  Future<void> actualizarRolUsuario(String idUsuario, RolUsuario rol) async {
    await _client
        .from('profiles')
        .update({'role': rol.toDbString()})
        .eq('id', idUsuario);
  }

  Future<void> alternarActivoUsuario(String idUsuario, bool estaActivo) async {
    await _client
        .from('profiles')
        .update({'is_active': estaActivo})
        .eq('id', idUsuario);
  }

  // Trae TODOS los días (activos e inactivos): el único consumidor es el
  // diálogo de edición del admin, que necesita saber cuáles quedaron
  // desactivados para mostrarlos así al reabrir — filtrar solo activos
  // hacía indistinguible "nunca configurado" de "desactivado a propósito".
  Future<List<Map<String, dynamic>>> obtenerHorarioEmpleado(String idEmpleado) async {
    final datos = await _client
        .from('work_schedules')
        .select()
        .eq('employee_id', idEmpleado);
    return (datos as List).cast<Map<String, dynamic>>();
  }

  Future<void> upsertDiaHorario({
    required String idEmpleado,
    required String diaSemana,
    required String horaInicio,
    required String horaFin,
    bool activo = true,
  }) async {
    await _client.from('work_schedules').upsert({
      'employee_id': idEmpleado,
      'tenant_id': kTenantIdActivo,
      'day_of_week': diaSemana,
      'start_time': horaInicio,
      'end_time': horaFin,
      'is_active': activo,
    }, onConflict: 'employee_id,day_of_week');
  }

  Future<void> asignarServicioAEmpleado(String idEmpleado, String idServicio) async {
    await _client.from('employee_services').upsert({
      'employee_id': idEmpleado,
      'service_id': idServicio,
      'tenant_id': kTenantIdActivo,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerDiasLibres(String idEmpleado) async {
    final datos = await _client
        .from('employee_time_off')
        .select()
        .eq('employee_id', idEmpleado)
        .gte('date', formatearFechaISO(DateTime.now()))
        .order('date');
    return (datos as List).cast<Map<String, dynamic>>();
  }

  Future<void> agregarDiaLibre({
    required String idEmpleado,
    required DateTime fecha,
    String? motivo,
  }) async {
    final fechaTexto = formatearFechaISO(fecha);
    await _client.from('employee_time_off').upsert({
      'employee_id': idEmpleado,
      'tenant_id': kTenantIdActivo,
      'date': fechaTexto,
      'reason': motivo,
    }, onConflict: 'employee_id,date');
  }

  Future<void> eliminarDiaLibre(String id) async {
    await _client.from('employee_time_off').delete().eq('id', id);
  }
}
