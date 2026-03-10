class Reserva {
  final String id;
  final String? usuarioId;
  final String empleadoId;
  final String appId;
  final String servicio;
  final DateTime inicio;
  final DateTime fin;
  final String estado;

  Reserva({
    required this.id,
    this.usuarioId,
    required this.empleadoId,
    required this.appId,
    required this.servicio,
    required this.inicio,
    required this.fin,
    required this.estado,
  });

  factory Reserva.fromMap(Map<String, dynamic> m) => Reserva(
        id: m['id'],
        usuarioId: m['user_id'],
        empleadoId: m['employee_id'],
        appId: m['app_id'],
        servicio: m['service'],
        inicio: DateTime.parse(m['starts_at']),
        fin: DateTime.parse(m['ends_at']),
        estado: m['status'],
      );
}
