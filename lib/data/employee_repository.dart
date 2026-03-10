import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/profile.dart';
import '../domain/enums/user_role.dart';

class RepositorioEmpleado {
  final _client = Supabase.instance.client;

  Future<List<Perfil>> obtenerEmpleados() async {
    final datos = await _client
        .from('profiles')
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
    final datos = await _client
        .from('employee_services')
        .select('profiles!employee_id(*)')
        .eq('service_id', idServicio);
    return (datos as List)
        .map((e) => Perfil.fromMap(e['profiles'] as Map<String, dynamic>))
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

  Future<List<Map<String, dynamic>>> obtenerHorarioEmpleado(String idEmpleado) async {
    final datos = await _client
        .from('work_schedules')
        .select()
        .eq('employee_id', idEmpleado)
        .eq('is_active', true);
    return (datos as List).cast<Map<String, dynamic>>();
  }

  Future<void> upsertDiaHorario({
    required String idEmpleado,
    required String diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    await _client.from('work_schedules').upsert({
      'employee_id': idEmpleado,
      'day_of_week': diaSemana,
      'start_time': horaInicio,
      'end_time': horaFin,
      'is_active': true,
    }, onConflict: 'employee_id,day_of_week');
  }

  Future<void> asignarServicioAEmpleado(String idEmpleado, String idServicio) async {
    await _client.from('employee_services').upsert({
      'employee_id': idEmpleado,
      'service_id': idServicio,
    });
  }
}
