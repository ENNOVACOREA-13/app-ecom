class NotificacionApp {
  final String id;
  final String titulo;
  final String cuerpo;
  final String tipo;
  final String? relatedId;
  final bool leida;
  final DateTime creadaEn;

  const NotificacionApp({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    this.relatedId,
    required this.leida,
    required this.creadaEn,
  });

  factory NotificacionApp.fromMap(Map<String, dynamic> map) {
    return NotificacionApp(
      id: map['id'] as String,
      titulo: map['title'] as String,
      cuerpo: map['body'] as String,
      tipo: map['type'] as String? ?? 'general',
      relatedId: map['related_id'] as String?,
      leida: map['read'] as bool? ?? false,
      creadaEn: DateTime.parse(map['created_at'] as String),
    );
  }
}
