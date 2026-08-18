import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Convierte un monto en pesos/dólares a centavos (lo que espera Stripe).
/// Usa round() en vez de toInt(): por imprecisión de punto flotante,
/// 19.99 * 100 da 1998.9999999999998, y toInt() lo truncaría a 1998
/// centavos ($19.98) en vez de los 1999 ($19.99) correctos — un cobro de
/// menos silencioso en cualquier precio terminado en .99.
int centavosDesdeMonto(double monto) => (monto * 100).round();

class ServicioStripe {
  static const _funcionUrl = '$kSupabaseUrl/functions/v1/create-payment-intent';

  /// Llama a la Edge Function de Supabase para crear un PaymentIntent.
  /// Devuelve {clientSecret, paymentIntentId}
  Future<Map<String, dynamic>> crearPaymentIntent({
    required double monto,
    String moneda = 'usd',
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await http.post(
      Uri.parse(_funcionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session?.accessToken ?? ''}',
      },
      body: jsonEncode({
        'amount': centavosDesdeMonto(monto),
        'currency': moneda,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al conectar con Stripe: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
