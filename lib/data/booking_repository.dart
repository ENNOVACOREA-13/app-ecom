import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/booking.dart';
import '../domain/models/slot.dart';
import '../domain/enums/booking_status.dart';

class RepositorioReserva {
  final _client = Supabase.instance.client;

  /// Obtener slots disponibles llamando a la función RPC de Supabase
  Future<List<Turno>> obtenerTurnosDisponibles({
    required String idEmpleado,
    required DateTime fecha,
    required int duracionMin,
  }) async {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    if (soloFecha.isBefore(soloHoy)) {
      throw Exception('DATE_IN_PAST');
    }
    final fechaTexto =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final resultado = await _client.rpc('get_available_slots', params: {
      'p_employee_id': idEmpleado,
      'p_date': fechaTexto,
      'p_duration_min': duracionMin,
    });
    return (resultado as List).map((e) => Turno.fromMap(e)).toList();
  }

  /// Crear una reserva (vía función SECURITY DEFINER para evitar problemas de RLS)
  /// El precio real se calcula en el servidor (crear_reserva) a partir del
  /// precio vigente del servicio — el cliente no lo controla.
  Future<Reserva> crearReserva({
    required String idCliente,
    required String idEmpleado,
    required String idServicio,
    required DateTime fecha,
    required String horaInicio,
    String? notas,
    List<String> idsExtras = const [],
  }) async {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    if (soloFecha.isBefore(soloHoy)) {
      throw Exception('DATE_IN_PAST');
    }
    final fechaTexto =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final resultado = await _client.rpc('crear_reserva', params: {
      'p_employee_id': idEmpleado,
      'p_service_id': idServicio,
      'p_date': fechaTexto,
      'p_start_time': '$horaInicio:00',
      'p_notes': notas,
      'p_extra_ids': idsExtras.isEmpty ? null : idsExtras,
    });
    final lista = resultado as List;
    if (lista.isEmpty) throw Exception('No se pudo crear la reserva');
    return Reserva.fromMap(lista.first as Map<String, dynamic>);
  }

  /// Reservas del cliente actual (con info del empleado y servicio)
  Future<List<Reserva>> obtenerReservasCliente(String idCliente) async {
    final idReal = _client.auth.currentUser?.id ?? idCliente;
    final datos = await _client
        .from('bookings_detailed')
        .select()
        .eq('client_id', idReal)
        .order('booking_date', ascending: false)
        .order('start_time', ascending: false);
    return (datos as List)
        .map((e) => Reserva.fromMap({
              ...e,
              'client_id': idReal,
            }))
        .toList();
  }

  /// Reservas del empleado (con info del cliente y servicio)
  Future<List<Reserva>> obtenerReservasEmpleado(String idEmpleado) async {
    final datos = await _client
        .from('bookings_detailed')
        .select()
        .eq('employee_id', idEmpleado)
        .order('booking_date', ascending: false)
        .order('start_time', ascending: false);
    return (datos as List)
        .map((e) => Reserva.fromMap({
              ...e,
              'employee_id': idEmpleado,
            }))
        .toList();
  }

  /// Una sola reserva por id (para validar el QR justo antes de marcarla pagada)
  Future<Reserva?> obtenerReservaPorId(String id) async {
    final datos = await _client
        .from('bookings_detailed')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (datos == null) return null;
    return Reserva.fromMap(datos);
  }

  /// Todas las reservas (admin)
  Future<List<Reserva>> obtenerTodasLasReservas({
    EstadoReserva? estado,
    int desde = 0,
    int cantidad = 100,
  }) async {
    var consulta = _client.from('bookings_detailed').select();
    if (estado != null) {
      consulta = consulta.eq('status', estado.toDbString());
    }
    final datos = await consulta
        .order('booking_date', ascending: false)
        .range(desde, desde + cantidad - 1);
    return (datos as List).map((e) => Reserva.fromMap(e)).toList();
  }

  /// Cancelar reserva (usa RPC SECURITY DEFINER para evitar bloqueo de RLS)
  Future<void> cancelarReserva(
      String idReserva, String canceladoPor, String? motivo) async {
    await _client.rpc('cancelar_reserva', params: {
      'p_booking_id': idReserva,
      'p_cancel_reason': motivo,
    });
  }

  /// Cambiar estado de reserva (para empleados/admin) — usa RPC para bypassear RLS
  Future<void> actualizarEstado(
      String idReserva, EstadoReserva nuevoEstado) async {
    await _client.rpc('actualizar_estado_reserva', params: {
      'p_booking_id': idReserva,
      'p_status': nuevoEstado.toDbString(),
    });
  }

  /// Cliente solicita cancelar una reserva ya confirmada (requiere aprobación del admin)
  Future<void> solicitarCancelacion(String idReserva) async {
    await _client.rpc('solicitar_cancelacion_reserva', params: {
      'p_booking_id': idReserva,
    });
  }

  /// Admin rechaza la solicitud de cancelación (la reserva sigue confirmada)
  Future<void> rechazarSolicitudCancelacion(String idReserva) async {
    await _client
        .from('bookings')
        .update({'cancel_requested': false})
        .eq('id', idReserva);
  }

  /// Estadísticas de empleado
  Future<Map<String, dynamic>> obtenerEstadisticasEmpleado(
      String idEmpleado) async {
    final datos = await _client
        .from('employee_stats')
        .select()
        .eq('employee_id', idEmpleado)
        .maybeSingle();
    return datos ?? {};
  }

  /// Estadísticas globales (admin)
  Future<List<Map<String, dynamic>>> obtenerTodasEstadisticasEmpleados() async {
    final datos = await _client.from('employee_stats').select();
    return (datos as List).cast<Map<String, dynamic>>();
  }

  /// Servicios más populares
  Future<List<Map<String, dynamic>>> obtenerServiciosPopulares() async {
    final datos = await _client.from('popular_services').select();
    return (datos as List).cast<Map<String, dynamic>>();
  }

  /// Reservas de hoy (realtime para admins)
  Future<List<Reserva>> obtenerReservasDeHoy() async {
    final hoy = DateTime.now();
    final fechaTexto =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final datos = await _client
        .from('bookings_detailed')
        .select()
        .eq('booking_date', fechaTexto)
        .order('start_time');
    return (datos as List).map((e) => Reserva.fromMap(e)).toList();
  }
}
