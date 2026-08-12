import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

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
        'amount': (monto * 100).toInt(), // Stripe usa centavos
        'currency': moneda,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al conectar con Stripe: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
