import 'package:flutter/material.dart';

enum EstadoPedido { pending, confirmed, ready, delivered, cancelled }

extension EstadoPedidoX on EstadoPedido {
  String toDbString() {
    switch (this) {
      case EstadoPedido.pending:
        return 'pending';
      case EstadoPedido.confirmed:
        return 'confirmed';
      case EstadoPedido.ready:
        return 'ready';
      case EstadoPedido.delivered:
        return 'delivered';
      case EstadoPedido.cancelled:
        return 'cancelled';
    }
  }

  static EstadoPedido fromString(String s) {
    switch (s) {
      case 'confirmed':
        return EstadoPedido.confirmed;
      case 'ready':
        return EstadoPedido.ready;
      case 'delivered':
        return EstadoPedido.delivered;
      case 'cancelled':
        return EstadoPedido.cancelled;
      default:
        return EstadoPedido.pending;
    }
  }

  String get etiqueta {
    switch (this) {
      case EstadoPedido.pending:
        return 'Pendiente';
      case EstadoPedido.confirmed:
        return 'Confirmado';
      case EstadoPedido.ready:
        return 'Listo';
      case EstadoPedido.delivered:
        return 'Entregado';
      case EstadoPedido.cancelled:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case EstadoPedido.pending:
        return Colors.orange;
      case EstadoPedido.confirmed:
        return Colors.blue;
      case EstadoPedido.ready:
        return Colors.green;
      case EstadoPedido.delivered:
        return const Color(0xFF4ECDC4);
      case EstadoPedido.cancelled:
        return Colors.red;
    }
  }
}
