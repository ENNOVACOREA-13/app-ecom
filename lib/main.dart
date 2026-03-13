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
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/config_provider.dart';
import 'providers/commission_provider.dart';
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
        ChangeNotifierProvider(create: (_) => ProveedorCarrito()),
        ChangeNotifierProvider(create: (_) => ProveedorPedido()),
        ChangeNotifierProvider(create: (_) => ProveedorGuardados()),
        ChangeNotifierProvider(create: (_) => ProveedorConfig()..cargar()),
        ChangeNotifierProvider(create: (_) => ProveedorComision()),
      ],
      child: Consumer<ProveedorConfig>(
        builder: (_, config, __) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'BarberApp',
          theme: crearTema(config.colorPrimario),
          routerConfig: construirEnrutador(),
        ),
      ),
    );
  }
}
