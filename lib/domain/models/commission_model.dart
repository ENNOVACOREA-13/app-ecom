class ConfigComision {
  final String id;
  final String servicioId;
  final double monto; // monto fijo en $ por servicio

  const ConfigComision({
    required this.id,
    required this.servicioId,
    required this.monto,
  });

  factory ConfigComision.fromMap(Map<String, dynamic> map) => ConfigComision(
        id: map['id'] as String,
        servicioId: map['service_id'] as String,
        monto: (map['amount'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'service_id': servicioId,
        'amount': monto,
      };
}

class AjustesComision {
  final String id;
  final int diaCierre; // 0=Dom, 1=Lun ... 6=Sab
  final int horaCierre;
  final int minutoCierre;

  const AjustesComision({
    required this.id,
    required this.diaCierre,
    required this.horaCierre,
    required this.minutoCierre,
  });

  factory AjustesComision.fromMap(Map<String, dynamic> map) => AjustesComision(
        id: map['id'] as String,
        diaCierre: (map['cutoff_day'] as int?) ?? 0,
        horaCierre: (map['cutoff_hour'] as int?) ?? 23,
        minutoCierre: (map['cutoff_minute'] as int?) ?? 59,
      );

  String get nombreDia {
    const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return dias[diaCierre];
  }

  String get horaTexto =>
      '${horaCierre.toString().padLeft(2, '0')}:${minutoCierre.toString().padLeft(2, '0')}';
}

class EntradaComision {
  final String id;
  final String? empleadoId;
  final String reservaId;
  final String? servicioId;
  final String nombreServicio;
  final double precioServicio;
  final double monto; // monto fijo de comisión en $
  final String? corteId;
  final DateTime ganadorEl;

  const EntradaComision({
    required this.id,
    this.empleadoId,
    required this.reservaId,
    this.servicioId,
    required this.nombreServicio,
    required this.precioServicio,
    required this.monto,
    this.corteId,
    required this.ganadorEl,
  });

  factory EntradaComision.fromMap(Map<String, dynamic> map) => EntradaComision(
        id: map['id'] as String,
        empleadoId: map['employee_id'] as String?,
        reservaId: map['booking_id'] as String,
        servicioId: map['service_id'] as String?,
        nombreServicio: map['service_name'] as String? ?? 'Servicio',
        precioServicio: (map['service_price'] as num).toDouble(),
        monto: (map['commission_amount'] as num).toDouble(),
        corteId: map['cut_id'] as String?,
        ganadorEl: DateTime.parse(map['earned_at'] as String),
      );
}

class CorteComision {
  final String id;
  final String? empleadoId;
  final String? nombreEmpleado;
  final DateTime inicioSemana;
  final DateTime finSemana;
  final double montoTotal;
  final int cantidadServicios;
  final String estado; // pending | paid
  final String? notas;
  final DateTime creadoEl;

  const CorteComision({
    required this.id,
    this.empleadoId,
    this.nombreEmpleado,
    required this.inicioSemana,
    required this.finSemana,
    required this.montoTotal,
    required this.cantidadServicios,
    required this.estado,
    this.notas,
    required this.creadoEl,
  });

  factory CorteComision.fromMap(Map<String, dynamic> map) => CorteComision(
        id: map['id'] as String,
        empleadoId: map['employee_id'] as String?,
        nombreEmpleado: map['full_name'] as String?,
        inicioSemana: DateTime.parse(map['week_start'] as String),
        finSemana: DateTime.parse(map['week_end'] as String),
        montoTotal: (map['total_amount'] as num).toDouble(),
        cantidadServicios: (map['services_count'] as int?) ?? 0,
        estado: map['status'] as String? ?? 'pending',
        notas: map['notes'] as String?,
        creadoEl: DateTime.parse(map['created_at'] as String),
      );

  bool get estaPagado => estado == 'paid';
}
