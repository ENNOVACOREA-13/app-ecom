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

  Future<List<Pedido>> obtenerTodosPedidos({int desde = 0, int cantidad = 100}) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*), profiles(full_name, phone)')
        .order('created_at', ascending: false)
        .range(desde, desde + cantidad - 1);
    return (data as List).map((m) => Pedido.fromMap(m)).toList();
  }

  Future<void> actualizarEstado(String pedidoId, String estado) async {
    // Cambia el estado y restaura el stock (si aplica) atómicamente en el
    // servidor, para evitar condiciones de carrera con cancelaciones
    // concurrentes que compartan un mismo producto.
    await _client.rpc('actualizar_estado_pedido', params: {
      'p_order_id': pedidoId,
      'p_status': estado,
    });
  }
}
