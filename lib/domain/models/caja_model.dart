/// Resumen de un periodo (en vivo, "desde el último corte" — o desde
/// siempre si nunca se ha hecho uno) o de un corte ya guardado.
class ResumenPeriodo {
  final double ingresosServicios;
  final double ingresosTienda;
  final double ingresosTotales;
  final double comisionesPendientes;
  final double insumosComprados;
  final double gananciasNetas;
  final int serviciosCompletados;
  final int pedidosTotal;
  final int pedidosPendientes;
  final DateTime periodoDesde;

  const ResumenPeriodo({
    required this.ingresosServicios,
    required this.ingresosTienda,
    required this.ingresosTotales,
    required this.comisionesPendientes,
    required this.insumosComprados,
    required this.gananciasNetas,
    required this.serviciosCompletados,
    required this.pedidosTotal,
    required this.pedidosPendientes,
    required this.periodoDesde,
  });

  factory ResumenPeriodo.fromMap(Map<String, dynamic> map) => ResumenPeriodo(
        ingresosServicios: (map['ingresos_servicios'] as num).toDouble(),
        ingresosTienda: (map['ingresos_tienda'] as num).toDouble(),
        ingresosTotales: (map['ingresos_totales'] as num).toDouble(),
        comisionesPendientes: (map['comisiones_pendientes'] as num).toDouble(),
        insumosComprados: (map['insumos_comprados'] as num).toDouble(),
        gananciasNetas: (map['ganancias_netas'] as num).toDouble(),
        serviciosCompletados: map['servicios_completados'] as int,
        pedidosTotal: map['pedidos_total'] as int,
        pedidosPendientes: map['pedidos_pendientes'] as int,
        periodoDesde: DateTime.parse(map['period_start'] as String),
      );
}

/// Resumen del periodo actual para UN empleado (su propio dashboard).
class ResumenPeriodoEmpleado {
  final int serviciosCompletados;
  final int serviciosPendientes;
  final int serviciosCancelados;
  final double ingresos;
  final double comisionesPendientes;

  const ResumenPeriodoEmpleado({
    required this.serviciosCompletados,
    required this.serviciosPendientes,
    required this.serviciosCancelados,
    required this.ingresos,
    required this.comisionesPendientes,
  });

  factory ResumenPeriodoEmpleado.fromMap(Map<String, dynamic> map) =>
      ResumenPeriodoEmpleado(
        serviciosCompletados: map['servicios_completados'] as int,
        serviciosPendientes: map['servicios_pendientes'] as int,
        serviciosCancelados: map['servicios_cancelados'] as int,
        ingresos: (map['ingresos'] as num).toDouble(),
        comisionesPendientes: (map['comisiones_pendientes'] as num).toDouble(),
      );
}

/// Un corte de caja ya guardado (reporte histórico de un periodo cerrado).
class CorteCaja {
  final String id;
  final DateTime periodoDesde;
  final DateTime periodoHasta;
  final double ingresosServicios;
  final double ingresosTienda;
  final double ingresosTotales;
  final double comisionesPendientes;
  final double insumosComprados;
  final double gananciasNetas;
  final int serviciosCompletados;
  final int pedidosTotal;
  final int pedidosPendientes;
  final DateTime creadoEl;

  const CorteCaja({
    required this.id,
    required this.periodoDesde,
    required this.periodoHasta,
    required this.ingresosServicios,
    required this.ingresosTienda,
    required this.ingresosTotales,
    required this.comisionesPendientes,
    required this.insumosComprados,
    required this.gananciasNetas,
    required this.serviciosCompletados,
    required this.pedidosTotal,
    required this.pedidosPendientes,
    required this.creadoEl,
  });

  factory CorteCaja.fromMap(Map<String, dynamic> map) => CorteCaja(
        id: map['id'] as String,
        periodoDesde: DateTime.parse(map['period_start'] as String),
        periodoHasta: DateTime.parse(map['period_end'] as String),
        ingresosServicios: (map['ingresos_servicios'] as num).toDouble(),
        ingresosTienda: (map['ingresos_tienda'] as num).toDouble(),
        ingresosTotales: (map['ingresos_totales'] as num).toDouble(),
        comisionesPendientes: (map['comisiones_pendientes'] as num).toDouble(),
        insumosComprados: (map['insumos_comprados'] as num).toDouble(),
        gananciasNetas: (map['ganancias_netas'] as num).toDouble(),
        serviciosCompletados: map['servicios_completados'] as int,
        pedidosTotal: map['pedidos_total'] as int,
        pedidosPendientes: map['pedidos_pendientes'] as int,
        creadoEl: DateTime.parse(map['created_at'] as String),
      );
}

/// Desglose de un empleado dentro de un corte guardado.
class EmpleadoCorte {
  final String? empleadoId;
  final String nombreEmpleado;
  final int serviciosCompletados;
  final double ingresos;
  final double comisiones;

  const EmpleadoCorte({
    this.empleadoId,
    required this.nombreEmpleado,
    required this.serviciosCompletados,
    required this.ingresos,
    required this.comisiones,
  });

  factory EmpleadoCorte.fromMap(Map<String, dynamic> map) => EmpleadoCorte(
        empleadoId: map['employee_id'] as String?,
        nombreEmpleado: map['employee_name'] as String,
        serviciosCompletados: map['servicios_completados'] as int,
        ingresos: (map['ingresos'] as num).toDouble(),
        comisiones: (map['comisiones'] as num).toDouble(),
      );
}
