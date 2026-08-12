import 'package:flutter/material.dart';

/// Set curado de iconos para servicios (barbería, estética, spa, negocio en
/// general), cada uno con palabras clave en español para la búsqueda.
class IconoServicio {
  final String nombre; // clave guardada en la base de datos
  final IconData icono;
  final List<String> etiquetas;
  const IconoServicio(this.nombre, this.icono, this.etiquetas);
}

const List<IconoServicio> kIconosServicio = [
  IconoServicio('content_cut', Icons.content_cut, ['corte', 'tijeras', 'cabello', 'pelo', 'barberia', 'peluqueria']),
  IconoServicio('face_retouching_natural', Icons.face_retouching_natural, ['rostro', 'facial', 'piel', 'cara', 'estetica']),
  IconoServicio('spa', Icons.spa, ['spa', 'relajacion', 'masaje', 'bienestar']),
  IconoServicio('brush', Icons.brush, ['brocha', 'maquillaje', 'pintura', 'estilo']),
  IconoServicio('colorize', Icons.colorize, ['tinte', 'color', 'pintar', 'colorimetria']),
  IconoServicio('format_paint', Icons.format_paint, ['tinte', 'color', 'pintura', 'brocha']),
  IconoServicio('water_drop', Icons.water_drop, ['agua', 'lavado', 'hidratacion', 'gotas']),
  IconoServicio('dry', Icons.dry, ['secado', 'secadora', 'viento']),
  IconoServicio('soap', Icons.soap, ['jabon', 'limpieza', 'lavado', 'higiene']),
  IconoServicio('clean_hands', Icons.clean_hands, ['limpieza', 'manos', 'higiene']),
  IconoServicio('face', Icons.face, ['rostro', 'cara', 'barba', 'afeitado']),
  IconoServicio('face_6', Icons.face_6, ['rostro', 'cara', 'hombre', 'barba']),
  IconoServicio('self_improvement', Icons.self_improvement, ['relajacion', 'bienestar', 'meditacion', 'spa']),
  IconoServicio('star', Icons.star, ['estrella', 'premium', 'destacado', 'favorito']),
  IconoServicio('star_border', Icons.star_border, ['estrella', 'premium', 'especial']),
  IconoServicio('auto_awesome', Icons.auto_awesome, ['brillo', 'especial', 'destacado', 'magia']),
  IconoServicio('diamond', Icons.diamond, ['diamante', 'lujo', 'premium', 'vip']),
  IconoServicio('card_giftcard', Icons.card_giftcard, ['regalo', 'paquete', 'combo', 'promocion']),
  IconoServicio('local_offer', Icons.local_offer, ['oferta', 'promocion', 'descuento', 'etiqueta']),
  IconoServicio('style', Icons.style, ['estilo', 'moda', 'peinado']),
  IconoServicio('straighten', Icons.straighten, ['medida', 'regla', 'alisado', 'precision']),
  IconoServicio('local_florist', Icons.local_florist, ['flor', 'aroma', 'natural', 'spa']),
  IconoServicio('palette', Icons.palette, ['color', 'paleta', 'tinte', 'diseno']),
  IconoServicio('checkroom', Icons.checkroom, ['ropa', 'vestuario', 'moda']),
  IconoServicio('watch', Icons.watch, ['tiempo', 'reloj', 'duracion']),
  IconoServicio('timer', Icons.timer, ['tiempo', 'duracion', 'rapido', 'exprés']),
  IconoServicio('favorite', Icons.favorite, ['favorito', 'popular', 'me gusta']),
  IconoServicio('emoji_events', Icons.emoji_events, ['premium', 'trofeo', 'top', 'mejor']),
  IconoServicio('category', Icons.category, ['categoria', 'general', 'otro']),
  IconoServicio('storefront', Icons.storefront, ['negocio', 'tienda', 'local']),
  IconoServicio('health_and_safety', Icons.health_and_safety, ['salud', 'seguridad', 'higiene']),
  IconoServicio('healing', Icons.healing, ['tratamiento', 'cuidado', 'salud']),
  IconoServicio('sanitizer', Icons.sanitizer, ['higiene', 'limpieza', 'desinfeccion']),
  IconoServicio('face_3', Icons.face_3, ['rostro', 'mujer', 'facial']),
  IconoServicio('accessibility_new', Icons.accessibility_new, ['cuerpo', 'postura', 'masaje']),
  IconoServicio('hot_tub', Icons.hot_tub, ['tina', 'spa', 'relajacion', 'agua']),
  IconoServicio('shower', Icons.shower, ['ducha', 'lavado', 'agua']),
  IconoServicio('cut', Icons.cut, ['cortar', 'tijeras', 'recorte']),
  IconoServicio('grass', Icons.grass, ['barba', 'vello', 'recorte']),
  IconoServicio('face_retouching_off', Icons.face_retouching_off, ['afeitado', 'rasurado', 'limpieza']),
];

const IconData kIconoServicioPorDefecto = Icons.content_cut;

IconData obtenerIconoServicio(String? nombreIcono) {
  if (nombreIcono == null) return kIconoServicioPorDefecto;
  for (final i in kIconosServicio) {
    if (i.nombre == nombreIcono) return i.icono;
  }
  return kIconoServicioPorDefecto;
}

List<IconoServicio> buscarIconosServicio(String consulta) {
  final q = consulta.trim().toLowerCase();
  if (q.isEmpty) return kIconosServicio;
  return kIconosServicio
      .where((i) => i.etiquetas.any((t) => t.contains(q)) || i.nombre.contains(q))
      .toList();
}

// ── Colores preset para el círculo del icono de cada servicio ──────────
const List<Color> kColoresIconoServicio = [
  Color(0xFF4ECDC4), Color(0xFF7C3AED), Color(0xFF007AFF), Color(0xFF34C759),
  Color(0xFFFF9500), Color(0xFFFF2D55), Color(0xFF5856D6), Color(0xFF1ABC9C),
  Color(0xFFFF6B6B), Color(0xFFE91E63), Color(0xFF2196F3), Color(0xFFFF5722),
];

Color? colorDesdeHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String colorAHex(Color color) =>
    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
