class ConfigLealtad {
  final bool activo;
  final String nombrePrograma;
  final double montoPorPunto;
  final double puntosPorPesoCanje;
  final bool ganaPorReservas;
  final bool ganaPorPedidos;

  const ConfigLealtad({
    required this.activo,
    required this.nombrePrograma,
    required this.montoPorPunto,
    required this.puntosPorPesoCanje,
    required this.ganaPorReservas,
    required this.ganaPorPedidos,
  });

  factory ConfigLealtad.fromMap(Map<String, dynamic> map) => ConfigLealtad(
        activo: map['activo'] as bool? ?? true,
        nombrePrograma: map['nombre_programa'] as String? ?? 'Programa de lealtad',
        montoPorPunto: (map['monto_por_punto'] as num?)?.toDouble() ?? 100,
        puntosPorPesoCanje: (map['puntos_por_peso_canje'] as num?)?.toDouble() ?? 10,
        ganaPorReservas: map['gana_por_reservas'] as bool? ?? true,
        ganaPorPedidos: map['gana_por_pedidos'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'activo': activo,
        'nombre_programa': nombrePrograma,
        'monto_por_punto': montoPorPunto,
        'puntos_por_peso_canje': puntosPorPesoCanje,
        'gana_por_reservas': ganaPorReservas,
        'gana_por_pedidos': ganaPorPedidos,
      };

  /// Cuántos puntos se ganan al gastar [monto].
  double puntosPorMonto(double monto) => (monto / montoPorPunto).floorToDouble();

  /// A cuántos pesos equivalen [puntos] al momento de canjear.
  double valorEnPesos(double puntos) => puntos / puntosPorPesoCanje;
}

class MovimientoLealtad {
  final String id;
  final String origen; // reserva | pedido | ajuste_manual
  final String? origenId;
  final double puntos;
  final String? descripcion;
  final DateTime creadoEl;

  const MovimientoLealtad({
    required this.id,
    required this.origen,
    this.origenId,
    required this.puntos,
    this.descripcion,
    required this.creadoEl,
  });

  factory MovimientoLealtad.fromMap(Map<String, dynamic> map) => MovimientoLealtad(
        id: map['id'] as String,
        origen: map['origen'] as String,
        origenId: map['origen_id'] as String?,
        puntos: (map['puntos'] as num).toDouble(),
        descripcion: map['descripcion'] as String?,
        creadoEl: DateTime.parse(map['created_at'] as String),
      );
}
