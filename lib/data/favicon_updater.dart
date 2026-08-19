import 'dart:js_interop';

@JS('setFavicon')
external void _setFavicon(String url);

/// Cambia el favicon del tab a la URL dada (logo del tenant actual) vía
/// dart:js_interop — el <link> estático en index.html es solo el genérico.
class ActualizadorFavicon {
  static void actualizar(String url) => _setFavicon(url);
}
