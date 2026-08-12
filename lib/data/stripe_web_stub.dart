/// Stub vacío para plataformas no-web (Android, iOS, Windows, etc.)
class ServicioStripeWeb {
  static void inicializar(String publishableKey) {}
  static Future<void> montarPaymentElement(String clientSecret, String containerId) async {}
  static Future<Map<String, dynamic>> confirmarPago(String returnUrl) async =>
      {'success': false, 'error': 'No disponible en esta plataforma'};
}
