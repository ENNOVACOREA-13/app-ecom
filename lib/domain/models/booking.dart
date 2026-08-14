import '../enums/booking_status.dart';

class Reserva {
  final String id;
  final String idCliente;
  final String idEmpleado;
  final String idServicio;
  final DateTime fechaReserva;
  final String horaInicio;
  final String horaFin;
  final EstadoReserva estado;
  final double precioTotal;
  final String? notas;
  final DateTime creadoEn;
  final DateTime? fechaPago;
  final bool cancelacionSolicitada;

  // Joined fields (nullable – solo cuando se hace JOIN)
  final String? nombreCliente;
  final String? nombreEmpleado;
  final String? nombreServicio;
  final int? duracionServicio;

  const Reserva({
    required this.id,
    required this.idCliente,
    required this.idEmpleado,
    required this.idServicio,
    required this.fechaReserva,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.precioTotal,
    this.notas,
    required this.creadoEn,
    this.fechaPago,
    this.cancelacionSolicitada = false,
    this.nombreCliente,
    this.nombreEmpleado,
    this.nombreServicio,
    this.duracionServicio,
  });

  factory Reserva.fromMap(Map<String, dynamic> map) {
    return Reserva(
      id: map['id'] as String,
      idCliente: map['client_id'] as String? ?? '',
      idEmpleado: map['employee_id'] as String? ?? '',
      idServicio: map['service_id'] as String? ?? '',
      fechaReserva: DateTime.parse(map['booking_date'] as String),
      horaInicio: (map['start_time'] as String).substring(0, 5),
      horaFin: (map['end_time'] as String).substring(0, 5),
      estado: EstadoReserva.fromString(map['status'] as String? ?? 'pending'),
      precioTotal: (map['total_price'] as num).toDouble(),
      notas: map['notes'] as String?,
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      fechaPago: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'] as String) : null,
      cancelacionSolicitada: map['cancel_requested'] as bool? ?? false,
      nombreCliente: map['client_name'] as String?,
      nombreEmpleado: map['employee_name'] as String?,
      nombreServicio: map['service_name'] as String?,
      duracionServicio: map['duration_min'] as int?,
    );
  }

  /// El cliente puede cancelar directo solo si está pendiente.
  bool get puedeCancelarDirecto => estado == EstadoReserva.pending;

  /// Reserva confirmada, sin solicitud de cancelación en curso todavía.
  bool get puedeSolicitarCancelacion =>
      estado == EstadoReserva.confirmed && !cancelacionSolicitada;
}
