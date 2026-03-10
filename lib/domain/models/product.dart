import '../enums/product_status.dart';

class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int existencias;
  final String? urlImagen;
  final EstadoProducto estado;
  final String creadoPor;
  final DateTime creadoEn;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.existencias,
    this.urlImagen,
    required this.estado,
    required this.creadoPor,
    required this.creadoEn,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as String,
      nombre: map['name'] as String,
      descripcion: map['description'] as String?,
      precio: (map['price'] as num).toDouble(),
      existencias: map['stock'] as int? ?? 0,
      urlImagen: map['image_url'] as String?,
      estado: EstadoProducto.fromString(map['status'] as String? ?? 'active'),
      creadoPor: map['created_by'] as String? ?? '',
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': nombre,
        'description': descripcion,
        'price': precio,
        'stock': existencias,
        'image_url': urlImagen,
        'status': estado.toDbString(),
      };

  bool get estaDisponible => estado == EstadoProducto.active && existencias > 0;
}
