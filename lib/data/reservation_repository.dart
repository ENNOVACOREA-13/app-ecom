import '../domain/models/reservation.dart';
import 'auth_repository.dart';
import 'supabase_service.dart';

class RepoReservas {
  Future<List<Reserva>> listarTodas() async {
    final data = await sbSelect('reservations');
    return data.map(Reserva.fromMap).toList();
  }

  /// Reservas del empleado actual (por employeeId local o de Supabase)
  Future<List<Reserva>> misReservasEmpleado() async {
    // Verificar si es usuario local con employeeId
    final usuarioLocal = SesionLocal.usuarioActual;
    if (usuarioLocal != null && usuarioLocal.employeeId != null) {
      final data = await sbSelect('reservations',
          where: {'employee_id': usuarioLocal.employeeId});
      return data.map(Reserva.fromMap).toList();
    }

    // Si no, buscar en Supabase
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return [];
    final emp = await sbSingle('employees', where: {'user_id': uid});
    if (emp == null) return [];
    final data =
        await sbSelect('reservations', where: {'employee_id': emp['id']});
    return data.map(Reserva.fromMap).toList();
  }

  /// Reservas del usuario actual (por userId local o de Supabase)
  Future<List<Reserva>> misReservasUsuario() async {
    // Verificar si es usuario local
    final usuarioLocal = SesionLocal.usuarioActual;
    if (usuarioLocal != null) {
      final data =
          await sbSelect('reservations', where: {'user_id': usuarioLocal.id});
      return data.map(Reserva.fromMap).toList();
    }

    // Si no, buscar en Supabase
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await sbSelect('reservations', where: {'user_id': uid});
    return data.map(Reserva.fromMap).toList();
  }

  Future<void> crearReserva({
    required String employeeId,
    required DateTime startsAt,
    required String service,
    required String appId,
  }) async {
    // Para Supabase: usar UUID real. Para usuarios locales: null
    final userId = sb.auth.currentUser?.id;

    final endsAt = startsAt.add(const Duration(hours: 1));
    await sbInsertReturn('reservations', {
      'employee_id': employeeId,
      'user_id': userId, // null para usuarios locales
      'app_id': appId,
      'service': service,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'created_by': userId, // null para usuarios locales
    });
  }
}
