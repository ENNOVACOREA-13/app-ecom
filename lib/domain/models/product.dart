import '../enums/product_status.dart';

class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final double? precioOferta;
  final int existencias;
  final String? urlImagen;
  final EstadoProducto estado;
  final String creadoPor;
  final DateTime creadoEn;
  final String? categoriaId;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.precioOferta,
    required this.existencias,
    this.urlImagen,
    required this.estado,
    required this.creadoPor,
    required this.creadoEn,
    this.categoriaId,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as String,
      nombre: map['name'] as String,
      descripcion: map['description'] as String?,
      precio: (map['price'] as num).toDouble(),
      precioOferta: map['sale_price'] != null ? (map['sale_price'] as num).toDouble() : null,
      existencias: map['stock'] as int? ?? 0,
      urlImagen: map['image_url'] as String?,
      estado: EstadoProducto.fromString(map['status'] as String? ?? 'active'),
      creadoPor: map['created_by'] as String? ?? '',
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      categoriaId: map['category_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': nombre,
        'description': descripcion,
        'price': precio,
        'sale_price': precioOferta,
        'stock': existencias,
        'image_url': urlImagen,
        'status': estado.toDbString(),
        'category_id': categoriaId,
      };

  bool get estaDisponible => estado == EstadoProducto.active && existencias > 0;
  int? get porcentajeOff {
    if (precioOferta == null || precioOferta! >= precio) return null;
    return ((precio - precioOferta!) / precio * 100).round();
  }
}
