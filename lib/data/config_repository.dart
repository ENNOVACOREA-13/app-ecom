import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RepositorioConfig {
  final _db = Supabase.instance.client;

  Future<Color?> obtenerColorPrimario() async {
    try {
      final data = await _db
          .from('app_config')
          .select('primary_color')
          .single();
      final hex = data['primary_color'] as String?;
      if (hex == null || hex.isEmpty) return null;
      return _hexAColor(hex);
    } catch (_) {
      return null;
    }
  }

  Future<bool> actualizarColorPrimario(Color color) async {
    try {
      final hex =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      await _db.from('app_config').upsert({
        'id': true,
        'primary_color': hex,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Color _hexAColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
