import '../enums/order_status.dart';

class ItemPedido {
  final String id;
  final String pedidoId;
  final String productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  const ItemPedido({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    return ItemPedido(
      id: map['id'] as String,
      pedidoId: map['order_id'] as String,
      productoId: map['product_id'] as String,
      nombreProducto: map['product_name'] as String,
      cantidad: map['quantity'] as int,
      precioUnitario: (map['unit_price'] as num).toDouble(),
    );
  }

  double get subtotal => cantidad * precioUnitario;
}

class Pedido {
  final String id;
  final String? clienteId;
  final EstadoPedido estado;
  final double total;
  final String? notas;
  final DateTime creadoEn;
  final List<ItemPedido> items;
  final String? nombreCliente;
  final String? telefonoCliente;
  final String metodoPago; // 'cash' | 'card' | 'transfer'
  final String estadoPago; // 'pending' | 'paid'
  final String? stripePaymentId;

  const Pedido({
    required this.id,
    this.clienteId,
    required this.estado,
    required this.total,
    this.notas,
    required this.creadoEn,
    this.items = const [],
    this.nombreCliente,
    this.telefonoCliente,
    this.metodoPago = 'cash',
    this.estadoPago = 'pending',
    this.stripePaymentId,
  });

  factory Pedido.fromMap(Map<String, dynamic> map) {
    final itemsData = map['order_items'] as List<dynamic>? ?? [];
    final profileData = map['profiles'] as Map<String, dynamic>?;
    return Pedido(
      id: map['id'] as String,
      clienteId: map['client_id'] as String?,
      estado: EstadoPedidoX.fromString(map['status'] as String? ?? 'pending'),
      total: (map['total'] as num).toDouble(),
      notas: map['notes'] as String?,
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      items: itemsData.map((i) => ItemPedido.fromMap(i as Map<String, dynamic>)).toList(),
      nombreCliente: profileData?['full_name'] as String?,
      telefonoCliente: profileData?['phone'] as String?,
      metodoPago: map['payment_method'] as String? ?? 'cash',
      estadoPago: map['payment_status'] as String? ?? 'pending',
      stripePaymentId: map['stripe_payment_id'] as String?,
    );
  }
}
