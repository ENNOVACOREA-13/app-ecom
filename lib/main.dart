import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/service_provider.dart';
import 'providers/product_provider.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BarberApp());
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProveedorAuth()..inicializar()),
        ChangeNotifierProvider(create: (_) => ProveedorReserva()),
        ChangeNotifierProvider(create: (_) => ProveedorServicio()),
        ChangeNotifierProvider(create: (_) => ProveedorProducto()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'BarberApp',
        theme: temaApp,
        routerConfig: construirEnrutador(),
      ),
    );
  }
}
