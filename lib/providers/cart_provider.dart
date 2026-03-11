import 'package:flutter/material.dart';
import '../domain/models/product.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito({required this.producto, this.cantidad = 1});
  double get subtotal => producto.precio * cantidad;
}

class ProveedorCarrito extends ChangeNotifier {
  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.cantidad);
  double get total => _items.fold(0.0, (s, i) => s + i.subtotal);
  bool get vacio => _items.isEmpty;

  void agregar(Producto producto) {
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    if (idx >= 0) {
      _items[idx].cantidad++;
    } else {
      _items.add(ItemCarrito(producto: producto));
    }
    notifyListeners();
  }

  void decrementar(String productoId) {
    final idx = _items.indexWhere((i) => i.producto.id == productoId);
    if (idx >= 0) {
      if (_items[idx].cantidad > 1) {
        _items[idx].cantidad--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void quitar(String productoId) {
    _items.removeWhere((i) => i.producto.id == productoId);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  bool contiene(String productoId) => _items.any((i) => i.producto.id == productoId);

  int cantidadProducto(String productoId) {
    final item = _items.where((i) => i.producto.id == productoId).firstOrNull;
    return item?.cantidad ?? 0;
  }
}
