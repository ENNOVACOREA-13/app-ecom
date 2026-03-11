import 'package:flutter/material.dart';
import '../data/order_repository.dart';
import '../domain/models/order.dart';
import 'cart_provider.dart';

class ProveedorPedido extends ChangeNotifier {
  final _repo = RepositorioPedido();
  List<Pedido> _pedidos = [];
  bool _cargando = false;
  String? _error;

  List<Pedido> get pedidos => _pedidos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<bool> realizarPedido({
    required String clienteId,
    required List<ItemCarrito> items,
    String? notas,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.crearPedido(clienteId: clienteId, items: items, notas: notas);
      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
      return false;
    }
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
      _pedidos = await _repo.obtenerTodosPedidos();
    } catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> actualizarEstado(String pedidoId, String estado) async {
    await _repo.actualizarEstado(pedidoId, estado);
    await cargarTodosPedidos();
  }
}
