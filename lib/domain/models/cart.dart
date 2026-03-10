class Carrito {
  final String id;
  final String? usuarioId;
  Carrito({required this.id, this.usuarioId});
  factory Carrito.fromMap(Map<String, dynamic> m) => Carrito(id: m['id'], usuarioId: m['user_id']);
}

class ItemCarrito {
  final String id;
  final String carritoId;
  final String productoId;
  final int qty;
  ItemCarrito({required this.id, required this.carritoId, required this.productoId, required this.qty});
  factory ItemCarrito.fromMap(Map<String, dynamic> m) => ItemCarrito(
    id: m['id'], carritoId: m['cart_id'], productoId: m['product_id'], qty: m['qty']);
}
