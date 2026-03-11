import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/order.dart';
import '../providers/cart_provider.dart';

class RepositorioPedido {
  final _client = Supabase.instance.client;

  Future<String> crearPedido({
    required String clienteId,
    required List<ItemCarrito> items,
    String? notas,
  }) async {
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    final pedido = await _client.from('orders').insert({
      'client_id': clienteId,
      'total': total,
      if (notas != null && notas.isNotEmpty) 'notes': notas,
    }).select().single();

    final pedidoId = pedido['id'] as String;
    await _client.from('order_items').insert(
      items
          .map((i) => {
                'order_id': pedidoId,
                'product_id': i.producto.id,
                'product_name': i.producto.nombre,
                'quantity': i.cantidad,
                'unit_price': i.producto.precio,
              })
          .toList(),
    );

    // Descontar stock de cada producto
    for (final item in items) {
      final row = await _client
          .from('products')
          .select('stock')
          .eq('id', item.producto.id)
          .single();
      final stockActual = (row['stock'] as int? ?? 0);
      final nuevoStock = (stockActual - item.cantidad).clamp(0, stockActual);
      await _client
          .from('products')
          .update({'stock': nuevoStock})
          .eq('id', item.producto.id);
    }

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
      'updated_at': DateTime.now().toIso8601String(),
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
