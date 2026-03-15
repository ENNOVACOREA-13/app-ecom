import '../domain/models/reservation.dart';
import 'supabase_service.dart';

class RepoReservas {
  Future<List<Reserva>> listarTodas() async {
    final data = await sbSelect('reservations');
    return data.map(Reserva.fromMap).toList();
  }

  /// Reservas del empleado actual
  Future<List<Reserva>> misReservasEmpleado() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return [];
    final emp = await sbSingle('employees', where: {'user_id': uid});
    if (emp == null) return [];
    final data =
        await sbSelect('reservations', where: {'employee_id': emp['id']});
    return data.map(Reserva.fromMap).toList();
  }

  /// Reservas del usuario actual
  Future<List<Reserva>> misReservasUsuario() async {
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
