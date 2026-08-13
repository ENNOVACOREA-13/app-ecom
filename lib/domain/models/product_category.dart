class CategoriaProducto {
  final String id;
  final String nombre;
  final String icono;
  final String? imagenUrl;
  final int orden;

  const CategoriaProducto({
    required this.id,
    required this.nombre,
    required this.icono,
    this.imagenUrl,
    required this.orden,
  });

  factory CategoriaProducto.fromMap(Map<String, dynamic> map) => CategoriaProducto(
        id: map['id'] as String,
        nombre: map['name'] as String,
        icono: map['icon'] as String? ?? 'category',
        imagenUrl: map['image_url'] as String?,
        orden: map['sort_order'] as int? ?? 0,
      );
}
