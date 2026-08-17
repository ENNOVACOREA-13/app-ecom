import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/loyalty.dart';

class RepositorioLealtad {
  final _client = Supabase.instance.client;

  Future<ConfigLealtad> obtenerConfig() async {
    final datos = await _client.from('loyalty_config').select().single();
    return ConfigLealtad.fromMap(datos);
  }

  Future<void> actualizarConfig(ConfigLealtad config) async {
    await _client.from('loyalty_config').update(config.toMap()).eq('id', true);
  }

  Future<List<MovimientoLealtad>> obtenerMovimientos(String idPerfil) async {
    final datos = await _client
        .from('loyalty_points')
        .select()
        .eq('profile_id', idPerfil)
        .order('created_at', ascending: false);
    return (datos as List).map((e) => MovimientoLealtad.fromMap(e)).toList();
  }

  Future<double> obtenerSaldo(String idPerfil) async {
    final movimientos = await obtenerMovimientos(idPerfil);
    return movimientos.fold<double>(0.0, (total, m) => total + m.puntos);
  }

  Future<void> ajustarPuntos({
    required String idPerfil,
    required double puntos,
    String? descripcion,
  }) async {
    await _client.rpc('ajustar_puntos_lealtad', params: {
      'p_profile_id': idPerfil,
      'p_puntos': puntos,
      'p_descripcion': descripcion,
    });
  }
}
