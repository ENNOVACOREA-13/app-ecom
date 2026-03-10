class Orden {
  final String id;
  final String? usuarioId;
  final double total;
  final String estado;
  final DateTime creada;
  Orden({required this.id, this.usuarioId, required this.total, required this.estado, required this.creada});

  factory Orden.fromMap(Map<String, dynamic> m) => Orden(
    id: m['id'],
    usuarioId: m['user_id'],
    total: (m['total'] as num).toDouble(),
    estado: m['status'],
    creada: DateTime.parse(m['created_at']),
  );
}
