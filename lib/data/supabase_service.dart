import 'package:supabase_flutter/supabase_flutter.dart';

final sb = Supabase.instance.client;

// Normaliza: quita nulls y retorna Map<String, Object>
Map<String, Object> _safeWhere(Map<String, Object?>? src) {
  final out = <String, Object>{};
  if (src != null) {
    src.forEach((k, v) {
      if (v != null) out[k] = v;
    });
  }
  return out;
}

/// SELECT lista
Future<List<Map<String, dynamic>>> sbSelect(
  String table, {
  List<String>? columnas,
  Map<String, Object?>? where,
}) async {
  final sel = columnas?.join(',') ?? '*';
  final filtros = _safeWhere(where);

  final res = await sb.from(table).select(sel).match(filtros);
  // Supabase 2.x devuelve List<Map<String, dynamic>>
  return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

/// SELECT único
Future<Map<String, dynamic>?> sbSingle(
  String table, {
  Map<String, Object?>? where,
}) async {
  final filtros = _safeWhere(where);
  final res = await sb.from(table).select().match(filtros).maybeSingle();
  if (res == null) return null;
  return Map<String, dynamic>.from(res as Map);
}

/// INSERT y retorna fila
Future<Map<String, dynamic>> sbInsertReturn(
  String table,
  Map<String, Object?> values,
) async {
  final payload = _safeWhere(values);
  final res = await sb.from(table).insert(payload).select().single();
  return Map<String, dynamic>.from(res as Map);
}

/// UPDATE por igualdad
Future<void> sbUpdate(
  String table,
  Map<String, Object?> values, {
  required Map<String, Object?> where,
}) async {
  final payload = _safeWhere(values);
  final filtros = _safeWhere(where);
  var q = sb.from(table).update(payload);
  for (final e in filtros.entries) {
    q = q.eq(e.key, e.value); // value es Object no-null
  }
  await q;
}

/// DELETE por igualdad
Future<void> sbDelete(
  String table, {
  required Map<String, Object?> where,
}) async {
  final filtros = _safeWhere(where);
  var q = sb.from(table).delete();
  for (final e in filtros.entries) {
    q = q.eq(e.key, e.value); // value es Object no-null
  }
  await q;
}
