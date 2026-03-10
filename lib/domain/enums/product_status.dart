enum EstadoProducto {
  active,
  inactive,
  outOfStock;

  static EstadoProducto fromString(String value) {
    switch (value) {
      case 'inactive':
        return EstadoProducto.inactive;
      case 'out_of_stock':
        return EstadoProducto.outOfStock;
      default:
        return EstadoProducto.active;
    }
  }

  String toDbString() {
    switch (this) {
      case EstadoProducto.inactive:
        return 'inactive';
      case EstadoProducto.outOfStock:
        return 'out_of_stock';
      default:
        return 'active';
    }
  }
}
