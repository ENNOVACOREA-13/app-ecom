import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/stripe_web_service.dart'
    if (dart.library.io) 'data/stripe_web_stub.dart';
import 'data/favicon_updater.dart'
    if (dart.library.io) 'data/favicon_updater_stub.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'data/tenant_resolver.dart';
import 'ui/tenant_unavailable_page.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/service_provider.dart';
import 'providers/product_provider.dart';
import 'providers/product_category_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/saved_provider.dart';
import 'providers/config_provider.dart';
import 'providers/commission_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/tenant_provider.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);

  final tenant = await resolverTenant();

  if (tenant.status != null && tenant.status != 'active') {
    runApp(PaginaTenantNoDisponible(businessName: tenant.businessName));
    return;
  }

  kTenantIdActivo = tenant.tenantId;

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
    headers: tenant.tenantId != null ? {'x-tenant-id': tenant.tenantId!} : null,
  );

  if (kIsWeb) {
    ServicioStripeWeb.inicializar(kStripePublishableKey);
  } else {
    Stripe.publishableKey = kStripePublishableKey;
    await Stripe.instance.applySettings();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Se carga (y espera) ANTES de runApp para que el color/tema real ya
  // esté listo desde el primer frame — evita el "flash" del tema por
  // defecto mientras la config todavía se está pidiendo a la base.
  final proveedorConfig = ProveedorConfig();
  await proveedorConfig.cargar();

  runApp(BarberApp(
    proveedorConfig: proveedorConfig,
    nombreNegocio: tenant.businessName,
  ));
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class BarberApp extends StatefulWidget {
  final ProveedorConfig proveedorConfig;
  final String? nombreNegocio;
  const BarberApp({super.key, required this.proveedorConfig, this.nombreNegocio});

  @override
  State<BarberApp> createState() => _BarberAppState();
}

class _BarberAppState extends State<BarberApp> {
  bool _mostrandoSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _mostrandoSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrandoSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PaginaSplash(logoUrl: widget.proveedorConfig.logoUrl),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProveedorAuth()..inicializar()),
        ChangeNotifierProvider(create: (_) => ProveedorReserva()),
        ChangeNotifierProvider(create: (_) => ProveedorServicio()),
        ChangeNotifierProvider(create: (_) => ProveedorProducto()),
        ChangeNotifierProvider(
            create: (_) => ProveedorCategoriasProducto()..cargarCategorias()),
        ChangeNotifierProvider(create: (_) => ProveedorCarrito()),
        ChangeNotifierProvider(create: (_) => ProveedorPedido()),
        ChangeNotifierProvider(create: (_) => ProveedorGuardados()),
        ChangeNotifierProvider.value(value: widget.proveedorConfig),
        ChangeNotifierProvider(create: (_) => ProveedorComision()),
        ChangeNotifierProvider(create: (_) => ProveedorNotificaciones()),
        ChangeNotifierProvider(create: (_) => ProveedorTenants()),
      ],
      child: Consumer<ProveedorConfig>(
        builder: (_, config, __) {
          // kBackground es leído directo (sin pasar por Theme) en varias
          // pantallas — se actualiza aquí para que la vista previa del
          // sysadmin y el color publicado se reflejen en toda la app.
          kBackground = config.colorSecundarioEfectivo;
          // El tab del navegador debe reflejar el negocio del dominio
          // actual, no un nombre genérico fijo — y el favicon el logo que
          // ese negocio haya subido (si no subió uno, se queda el genérico
          // de PrettyCore ya puesto en index.html).
          if (kIsWeb && config.logoUrl != null && config.logoUrl!.isNotEmpty) {
            ActualizadorFavicon.actualizar(config.logoUrl!);
          }
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: widget.nombreNegocio ?? 'PrettyCore',
            theme: crearTema(
              config.colorPrimarioEfectivo,
              fontFamily: config.fontFamilyEfectiva,
              radioContenedor: config.radioContenedorEfectivo,
              sombraContenedor: config.sombraContenedorEfectiva,
            ),
            routerConfig: construirEnrutador(navigatorKey: rootNavigatorKey),
            builder: (context, child) => _SesionExpiradaListener(child: child!),
          );
        },
      ),
    );
  }
}

class PaginaSplash extends StatelessWidget {
  final String? logoUrl;
  const PaginaSplash({super.key, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? Image.network(logoUrl!, width: 120, height: 120, fit: BoxFit.cover)
                  : Image.asset(
                      kLogoBarberiaAsset,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
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
    if (auth.cuentaDesactivada && !auth.inicializando && !_mostrandoDialogo) {
      _mostrandoDialogo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarDialogoDesactivada();
      });
    } else if (auth.sesionExpirada &&
        !auth.inicializando &&
        !_mostrandoDialogo) {
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

  void _mostrarDialogoDesactivada() {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    showDialog(
      context: navContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block, size: 48, color: Colors.red),
        title: const Text('Cuenta desactivada'),
        content: const Text(
          'Tu cuenta ha sido desactivada por el administrador.\nContacta al administrador si crees que es un error.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ProveedorAuth>().limpiarCuentaDesactivada();
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
