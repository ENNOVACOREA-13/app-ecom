import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Config del tenant resuelto para el dominio actual. `slug`/`status` son
/// `null` cuando se usó el fallback (localhost, sin match, o error de red) —
/// en ese caso `supabaseUrl`/`supabaseAnonKey` son los del proyecto plantilla
/// (constants.dart), no de ningún registro del control plane.
typedef ConfigTenant = ({
  String supabaseUrl,
  String supabaseAnonKey,
  String? slug,
  String? businessName,
  String? status,
});

const fallbackTenant = (
  supabaseUrl: kSupabaseUrl,
  supabaseAnonKey: kSupabaseAnonKey,
  slug: null,
  businessName: null,
  status: null,
);

/// true si [host] no sirve para buscar un tenant (vacío o localhost) — en
/// ese caso hay que usar el proyecto plantilla sin llamar al control plane.
bool esHostLocalOVacio(String host) =>
    host.isEmpty || host == 'localhost' || host == '127.0.0.1';

/// Interpreta las filas ya decodificadas de `resolve_tenant_by_domain`.
/// Cae al fallback si no hay match o si la fila no trae credenciales
/// completas de Supabase — nunca deja a la app apuntando a un proyecto a
/// medio configurar.
ConfigTenant parsearFilasTenant(List<dynamic> filas) {
  if (filas.isEmpty) return fallbackTenant;

  final fila = filas.first as Map<String, dynamic>;
  final url = fila['supabase_url'] as String?;
  final anonKey = fila['supabase_anon_key'] as String?;
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    return fallbackTenant;
  }

  return (
    supabaseUrl: url,
    supabaseAnonKey: anonKey,
    slug: fila['slug'] as String?,
    businessName: fila['business_name'] as String?,
    status: fila['status'] as String?,
  );
}

/// Resuelve a qué proyecto de Supabase pertenece el dominio actual,
/// consultando el control plane. Nunca bloquea el arranque: ante localhost,
/// falta de match, timeout o cualquier error, regresa el fallback (el
/// proyecto plantilla actual) en vez de lanzar una excepción.
Future<ConfigTenant> resolverTenant() async {
  if (!kIsWeb) return fallbackTenant;

  final host = Uri.base.host;
  if (esHostLocalOVacio(host)) {
    return fallbackTenant;
  }

  try {
    final respuesta = await http
        .post(
          Uri.parse('$kControlPlaneUrl/rpc/resolve_tenant_by_domain'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'p_domain': host}),
        )
        .timeout(const Duration(seconds: 4));

    if (respuesta.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('[tenant_resolver] status ${respuesta.statusCode} para "$host", uso fallback');
      }
      return fallbackTenant;
    }

    final filas = jsonDecode(respuesta.body) as List;
    if (filas.isEmpty && kDebugMode) {
      debugPrint('[tenant_resolver] sin match para "$host", uso fallback');
    }
    return parsearFilasTenant(filas);
  } catch (e) {
    if (kDebugMode) debugPrint('[tenant_resolver] error al resolver "$host": $e — uso fallback');
    return fallbackTenant;
  }
}
