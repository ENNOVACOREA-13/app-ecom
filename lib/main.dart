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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
          routerConfig: construirEnrutador(navigatorKey: rootNavigatorKey),
          builder: (context, child) => _SesionExpiradaListener(child: child!),
        ),
      ),
    );
  }
}

class _SesionExpiradaListener extends StatefulWidget {
  final Widget child;
  const _SesionExpiradaListener({required this.child});

  @override
  State<_SesionExpiradaListener> createState() =>
      _SesionExpiradaListenerState();
}

class _SesionExpiradaListenerState extends State<_SesionExpiradaListener> {
  bool _mostrandoDialogo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<ProveedorAuth>();
    if (auth.sesionExpirada && !auth.inicializando && !_mostrandoDialogo) {
      _mostrandoDialogo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarDialogoExpiracion();
      });
    }
  }

  void _mostrarDialogoExpiracion() {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    showDialog(
      context: navContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, size: 48, color: Colors.red),
        title: const Text('Sesión caducada'),
        content: const Text(
          'Tu sesión ha sido cerrada por el administrador.\nIntenta acceder de nuevo.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ProveedorAuth>().limpiarSesionExpirada();
                _mostrandoDialogo = false;
              },
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
