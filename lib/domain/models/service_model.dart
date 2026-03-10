class ModeloServicio {
  final String id;
  final String nombre;
  final String? descripcion;
  final int duracionMin;
  final double precio;
  final String? urlImagen;
  final bool estaActivo;

  const ModeloServicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.duracionMin,
    required this.precio,
    this.urlImagen,
    required this.estaActivo,
  });

  factory ModeloServicio.fromMap(Map<String, dynamic> map) {
    return ModeloServicio(
      id: map['id'] as String,
      nombre: map['name'] as String,
      descripcion: map['description'] as String?,
      duracionMin: map['duration_min'] as int? ?? 30,
      precio: (map['price'] as num).toDouble(),
      urlImagen: map['image_url'] as String?,
      estaActivo: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': nombre,
        'description': descripcion,
        'duration_min': duracionMin,
        'price': precio,
        'image_url': urlImagen,
        'is_active': estaActivo,
      };

  String get etiquetaDuracion {
    if (duracionMin < 60) return '${duracionMin}min';
    final h = duracionMin ~/ 60;
    final m = duracionMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
