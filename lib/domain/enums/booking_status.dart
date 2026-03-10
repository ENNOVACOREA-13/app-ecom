enum EstadoReserva {
  pending,
  confirmed,
  completed,
  cancelled;

  static EstadoReserva fromString(String value) {
    switch (value) {
      case 'confirmed':
        return EstadoReserva.confirmed;
      case 'completed':
        return EstadoReserva.completed;
      case 'cancelled':
        return EstadoReserva.cancelled;
      default:
        return EstadoReserva.pending;
    }
  }

  String toDbString() => name;

  String get label {
    switch (this) {
      case EstadoReserva.pending:
        return 'Pendiente';
      case EstadoReserva.confirmed:
        return 'Confirmada';
      case EstadoReserva.completed:
        return 'Completada';
      case EstadoReserva.cancelled:
        return 'Cancelada';
    }
  }
}
