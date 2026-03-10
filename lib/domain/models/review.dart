class Resena {
  final String id;
  final String idReserva;
  final String idCliente;
  final String idEmpleado;
  final int calificacion;
  final String? comentario;
  final DateTime creadoEn;

  const Resena({
    required this.id,
    required this.idReserva,
    required this.idCliente,
    required this.idEmpleado,
    required this.calificacion,
    this.comentario,
    required this.creadoEn,
  });

  factory Resena.fromMap(Map<String, dynamic> map) {
    return Resena(
      id: map['id'] as String,
      idReserva: map['booking_id'] as String,
      idCliente: map['client_id'] as String,
      idEmpleado: map['employee_id'] as String,
      calificacion: map['rating'] as int,
      comentario: map['comment'] as String?,
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
