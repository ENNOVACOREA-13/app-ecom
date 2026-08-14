import 'package:flutter/material.dart';
import '../data/order_repository.dart';
import '../domain/models/order.dart';
import 'cart_provider.dart';

class ProveedorPedido extends ChangeNotifier {
  static const _tamanoPagina = 100;

  final _repo = RepositorioPedido();
  List<Pedido> _pedidos = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMasPedidos = true;
  String? _error;

  List<Pedido> get pedidos => _pedidos;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMasPedidos => _hayMasPedidos;
  String? get error => _error;

  Future<bool> realizarPedido({
    required String clienteId,
    required List<ItemCarrito> items,
    String? notas,
    String metodoPago = 'cash',
    String estadoPago = 'pending',
    String? stripePaymentId,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.crearPedido(
        clienteId: clienteId,
        items: items,
        notas: notas,
        metodoPago: metodoPago,
        estadoPago: estadoPago,
        stripePaymentId: stripePaymentId,
      );
      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapearErrorPedido(e.toString());
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  String _mapearErrorPedido(String e) {
    if (e.contains('INSUFFICIENT_STOCK')) {
      return 'Uno de los productos ya no tiene stock suficiente. Revisa tu carrito.';
    }
    if (e.contains('EMPTY_CART')) return 'Tu carrito está vacío.';
    if (e.contains('PRODUCT_NOT_FOUND')) return 'Uno de los productos ya no está disponible.';
    if (e.contains('network') || e.contains('socket')) return 'Sin conexión a internet.';
    if (e.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo.';
    return 'Ocurrió un error al procesar tu pedido. Intenta de nuevo.';
  }

  Future<void> cargarPedidosCliente(String clienteId) async {
    _cargando = true;
    notifyListeners();
    try {
      _pedidos = await _repo.obtenerPedidosCliente(clienteId);
    } catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarTodosPedidos() async {
    _cargando = true;
    notifyListeners();
    try {
      final pagina = await _repo.obtenerTodosPedidos(desde: 0, cantidad: _tamanoPagina);
      _pedidos = pagina;
      _hayMasPedidos = pagina.length == _tamanoPagina;
    } catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarMasPedidos() async {
    if (_cargandoMas || !_hayMasPedidos) return;
    _cargandoMas = true;
    notifyListeners();
    try {
      final pagina = await _repo.obtenerTodosPedidos(
          desde: _pedidos.length, cantidad: _tamanoPagina);
      _pedidos = [..._pedidos, ...pagina];
      _hayMasPedidos = pagina.length == _tamanoPagina;
    } catch (e) {
      _error = e.toString();
    }
    _cargandoMas = false;
    notifyListeners();
  }

  Future<void> actualizarEstado(String pedidoId, String estado) async {
    await _repo.actualizarEstado(pedidoId, estado);
    await cargarTodosPedidos();
  }
}
