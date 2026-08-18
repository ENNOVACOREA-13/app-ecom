import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Tenant resuelto para el dominio actual. Todos los campos son `null`
/// cuando se usó el fallback (localhost, sin match, o error de red) — en
/// ese caso la app no manda header `x-tenant-id`, así que solo ve el
/// catálogo público vacío hasta que se resuelva un tenant real.
typedef ConfigTenant = ({
  String? tenantId,
  String? slug,
  String? businessName,
  String? status,
});

const fallbackTenant = (
  tenantId: null,
  slug: null,
  businessName: null,
  status: null,
);

/// true si [host] no sirve para buscar un tenant (vacío o localhost) — en
/// ese caso hay que usar el fallback sin llamar a la base.
bool esHostLocalOVacio(String host) =>
    host.isEmpty || host == 'localhost' || host == '127.0.0.1';

/// Interpreta las filas ya decodificadas de `resolve_tenant_by_domain`.
/// Cae al fallback si no hay match o si la fila no trae un tenant_id
/// completo — nunca deja a la app funcionando con un tenant a medias.
ConfigTenant parsearFilasTenant(List<dynamic> filas) {
  if (filas.isEmpty) return fallbackTenant;

  final fila = filas.first as Map<String, dynamic>;
  final tenantId = fila['tenant_id'] as String?;
  if (tenantId == null || tenantId.isEmpty) {
    return fallbackTenant;
  }

  return (
    tenantId: tenantId,
    slug: fila['slug'] as String?,
    businessName: fila['business_name'] as String?,
    status: fila['status'] as String?,
  );
}

/// Resuelve a qué tenant pertenece el dominio actual, consultando
/// resolve_tenant_by_domain() en el proyecto Supabase compartido. Nunca
/// bloquea el arranque: ante localhost, falta de match, timeout o
/// cualquier error, regresa el fallback en vez de lanzar una excepción.
Future<ConfigTenant> resolverTenant() async {
  if (!kIsWeb) return fallbackTenant;

  final host = Uri.base.host;
  if (esHostLocalOVacio(host)) {
    return fallbackTenant;
  }

  try {
    final respuesta = await http
        .post(
          Uri.parse('$kSupabaseUrl/rest/v1/rpc/resolve_tenant_by_domain'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': kSupabaseAnonKey,
            'Authorization': 'Bearer $kSupabaseAnonKey',
          },
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
