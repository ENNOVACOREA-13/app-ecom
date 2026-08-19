import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<Map<String, dynamic>> kSeccionesHomePorDefecto = [
  {'key': 'chips_categorias', 'visible': true},
  {'key': 'banner_hero', 'visible': true},
  {'key': 'categorias', 'visible': true},
  {'key': 'banner_promo', 'visible': true},
  {'key': 'productos', 'visible': true},
];

/// Agrega al final las secciones por defecto que falten en [secciones]
/// (p. ej. tras publicar un nuevo tipo de sección) sin alterar el orden
/// ni la visibilidad de las que el sysadmin ya configuró.
List<Map<String, dynamic>> completarSeccionesHome(List<Map<String, dynamic>> secciones) {
  final claves = secciones.map((s) => s['key'] as String).toSet();
  final faltantes = kSeccionesHomePorDefecto
      .where((s) => !claves.contains(s['key']))
      .map((s) => Map<String, dynamic>.from(s));
  return [...faltantes, ...secciones];
}

class RepositorioConfig {
  SupabaseClient get _db => Supabase.instance.client;

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
      final res = await _db.from('app_config').upsert({
        'id': true,
        'primary_color': hex,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Color _hexAColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<Color?> obtenerColorSecundario() async {
    try {
      final data = await _db
          .from('app_config')
          .select('background_color')
          .single();
      final hex = data['background_color'] as String?;
      if (hex == null || hex.isEmpty) return null;
      return _hexAColor(hex);
    } catch (_) {
      return null;
    }
  }

  Future<bool> obtenerTiendaHabilitada() async {
    try {
      final data = await _db
          .from('app_config')
          .select('store_enabled')
          .single();
      return data['store_enabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> actualizarTiendaHabilitada(bool habilitada) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'store_enabled': habilitada,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> obtenerLogoUrl() async {
    try {
      final data = await _db
          .from('app_config')
          .select('logo_url')
          .single();
      return data['logo_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> actualizarLogoUrl(String url) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'logo_url': url,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> obtenerEditorVistasAdmin() async {
    try {
      final data = await _db
          .from('app_config')
          .select('editor_vistas_admin')
          .single();
      return data['editor_vistas_admin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> actualizarEditorVistasAdmin(bool habilitado) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'editor_vistas_admin': habilitado,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<({List<String> imagenes, String? texto, String alineacion, String? botonTexto, String? botonLink})>
      obtenerBannerConfig() async {
    try {
      final data = await _db
          .from('app_config')
          .select('banner_images, banner_text, banner_align, banner_button_text, banner_button_link')
          .single();
      return (
        imagenes: ((data['banner_images'] as List?) ?? []).cast<String>(),
        texto: data['banner_text'] as String?,
        alineacion: data['banner_align'] as String? ?? 'left',
        botonTexto: data['banner_button_text'] as String?,
        botonLink: data['banner_button_link'] as String?,
      );
    } catch (_) {
      return (imagenes: <String>[], texto: null, alineacion: 'left', botonTexto: null, botonLink: null);
    }
  }

  Future<({String titulo, String forma, double tamanoIcono})> obtenerSeccionCategorias() async {
    try {
      final data = await _db
          .from('app_config')
          .select('home_categorias_titulo, home_categorias_forma, categorias_icono_tamano')
          .single();
      return (
        titulo: data['home_categorias_titulo'] as String? ?? 'Categorías de Servicios',
        forma: data['home_categorias_forma'] as String? ?? 'circulo',
        tamanoIcono: (data['categorias_icono_tamano'] as num?)?.toDouble() ?? 22,
      );
    } catch (_) {
      return (titulo: 'Categorías de Servicios', forma: 'circulo', tamanoIcono: 22.0);
    }
  }

  Future<bool> actualizarSeccionCategorias({
    required String titulo,
    required String forma,
    required double tamanoIcono,
  }) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'home_categorias_titulo': titulo,
        'home_categorias_forma': forma,
        'categorias_icono_tamano': tamanoIcono,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<({String fontFamily, double radioContenedor, double sombraContenedor})>
      obtenerEstiloApp() async {
    try {
      final data = await _db
          .from('app_config')
          .select('font_family, container_radius, container_shadow')
          .single();
      return (
        fontFamily: data['font_family'] as String? ?? 'Poppins',
        radioContenedor: (data['container_radius'] as num?)?.toDouble() ?? 16,
        sombraContenedor: (data['container_shadow'] as num?)?.toDouble() ?? 1,
      );
    } catch (_) {
      return (fontFamily: 'Poppins', radioContenedor: 16.0, sombraContenedor: 1.0);
    }
  }

  Future<bool> actualizarEstiloApp({
    required String fontFamily,
    required double radioContenedor,
    required double sombraContenedor,
  }) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'font_family': fontFamily,
        'container_radius': radioContenedor,
        'container_shadow': sombraContenedor,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> obtenerTituloProductos() async {
    try {
      final data = await _db
          .from('app_config')
          .select('home_productos_titulo')
          .single();
      return data['home_productos_titulo'] as String? ?? 'Productos Populares';
    } catch (_) {
      return 'Productos Populares';
    }
  }

  Future<bool> actualizarTituloProductos(String titulo) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'home_productos_titulo': titulo,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerSeccionesHome() async {
    try {
      final data = await _db
          .from('app_config')
          .select('home_sections')
          .single();
      final lista = data['home_sections'] as List?;
      if (lista == null || lista.isEmpty) return kSeccionesHomePorDefecto;
      return completarSeccionesHome(lista.cast<Map<String, dynamic>>());
    } catch (_) {
      return kSeccionesHomePorDefecto;
    }
  }

  Future<bool> actualizarSeccionesHome(List<Map<String, dynamic>> secciones) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'home_sections': secciones,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> obtenerBorrador() async {
    try {
      final data = await _db
          .from('app_config')
          .select('draft_config')
          .single();
      return data['draft_config'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> guardarBorrador(Map<String, dynamic> borrador) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'draft_config': borrador,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> descartarBorrador() async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'draft_config': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> publicarBorrador(Map<String, dynamic> borrador) async {
    try {
      final res = await _db.from('app_config').upsert({
        'id': true,
        'primary_color': borrador['primary_color'],
        'background_color': borrador['background_color'],
        'font_family': borrador['font_family'],
        'container_radius': borrador['container_radius'],
        'container_shadow': borrador['container_shadow'],
        'banner_images': borrador['banner_images'],
        'banner_text': borrador['banner_text'],
        'banner_align': borrador['banner_align'],
        'banner_button_text': borrador['banner_button_text'],
        'banner_button_link': borrador['banner_button_link'],
        'home_categorias_titulo': borrador['home_categorias_titulo'],
        'home_categorias_forma': borrador['home_categorias_forma'],
        'categorias_icono_tamano': borrador['categorias_icono_tamano'],
        'home_productos_titulo': borrador['home_productos_titulo'],
        'home_sections': borrador['home_sections'],
        'draft_config': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return (res).isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
