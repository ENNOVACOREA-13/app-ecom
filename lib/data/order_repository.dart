import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/order.dart';
import '../providers/cart_provider.dart';

class RepositorioPedido {
  final _client = Supabase.instance.client;

  Future<String> crearPedido({
    required String clienteId,
    required List<ItemCarrito> items,
    String? notas,
    String metodoPago = 'cash',
    String estadoPago = 'pending',
    String? stripePaymentId,
  }) async {
    // El precio real se calcula en el servidor (crear_pedido) a partir del
    // precio vigente de cada producto — el cliente solo manda id y cantidad.
    final pedidoId = await _client.rpc('crear_pedido', params: {
      'p_items': items
          .map((i) => {
                'product_id': i.producto.id,
                'cantidad': i.cantidad,
              })
          .toList(),
      'p_notes': (notas != null && notas.isNotEmpty) ? notas : null,
      'p_payment_method': metodoPago,
      'p_payment_status': estadoPago,
      'p_stripe_payment_id': stripePaymentId,
    }) as String;

    return pedidoId;
  }

  Future<List<Pedido>> obtenerPedidosCliente(String clienteId) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('client_id', clienteId)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Pedido.fromMap(m)).toList();
  }

  Future<List<Pedido>> obtenerTodosPedidos() async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*), profiles(full_name, phone)')
        .order('created_at', ascending: false);
    return (data as List).map((m) => Pedido.fromMap(m)).toList();
  }

  Future<void> actualizarEstado(String pedidoId, String estado) async {
    // Verificar estado actual para evitar restaurar stock doble
    final pedidoActual = await _client
        .from('orders')
        .select('status')
        .eq('id', pedidoId)
        .single();
    final estadoActual = pedidoActual['status'] as String? ?? '';

    await _client.from('orders').update({
      'status': estado,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pedidoId);

    // Restaurar stock solo si se cancela y no estaba ya cancelado
    if (estado == 'cancelled' && estadoActual != 'cancelled') {
      final itemsData = await _client
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', pedidoId);

      for (final item in itemsData as List) {
        final productId = item['product_id'] as String;
        final cantidad = item['quantity'] as int;
        final row = await _client
            .from('products')
            .select('stock')
            .eq('id', productId)
            .single();
        final stockActual = (row['stock'] as int? ?? 0);
        await _client
            .from('products')
            .update({'stock': stockActual + cantidad})
            .eq('id', productId);
      }
    }
  }
}
