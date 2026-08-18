/// true si [fecha] (comparando solo año/mes/día, sin hora) ya pasó respecto
/// a [ahora] (por defecto la fecha actual del sistema).
bool esFechaPasada(DateTime fecha, {DateTime? ahora}) {
  final ref = ahora ?? DateTime.now();
  final soloRef = DateTime(ref.year, ref.month, ref.day);
  final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
  return soloFecha.isBefore(soloRef);
}

/// Formatea [fecha] como 'yyyy-MM-dd' (lo que esperan los parámetros `date`
/// de las funciones RPC de Supabase).
String formatearFechaISO(DateTime fecha) =>
    '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

/// Lunes (medianoche) de la semana que contiene [ahora].
DateTime inicioDeSemana(DateTime ahora) {
  final diasDesdeLunes = ahora.weekday - 1; // DateTime.weekday: Monday=1
  return DateTime(ahora.year, ahora.month, ahora.day - diasDesdeLunes);
}
