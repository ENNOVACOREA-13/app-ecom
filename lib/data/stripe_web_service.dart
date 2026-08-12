import 'dart:async';
import 'dart:js_interop';

@JS('initStripe')
external void _initStripe(String publishableKey);

@JS('stripeCreatePaymentElement')
external JSPromise _createPaymentElement(String clientSecret, String containerId);

@JS('stripeConfirmPayment')
external JSPromise _confirmPayment(String returnUrl);

extension type _StripeResult._(JSObject _) implements JSObject {
  external JSBoolean get success;
  external JSString? get paymentIntentId;
  external JSString? get error;
}

/// Servicio que llama a Stripe.js desde Flutter Web vía dart:js_interop
class ServicioStripeWeb {
  static bool _inicializado = false;

  static void inicializar(String publishableKey) {
    if (_inicializado) return;
    _initStripe(publishableKey);
    _inicializado = true;
  }

  static Future<void> montarPaymentElement(
      String clientSecret, String containerId) async {
    await _createPaymentElement(clientSecret, containerId).toDart;
  }

  static Future<Map<String, dynamic>> confirmarPago(String returnUrl) async {
    final jsResult = await _confirmPayment(returnUrl).toDart;
    final result = jsResult as _StripeResult;
    final success = result.success.toDart;
    if (success) {
      return {
        'success': true,
        'paymentIntentId': result.paymentIntentId?.toDart ?? '',
      };
    } else {
      return {
        'success': false,
        'error': result.error?.toDart ?? 'Error desconocido',
      };
    }
  }
}
