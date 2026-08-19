import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../ui/auth/login_page.dart';
import '../ui/auth/register_page.dart';
import '../ui/auth/forgot_password_page.dart';
import '../ui/shell/app_shell.dart';
import '../ui/booking/select_service_page.dart';
import '../ui/booking/select_slot_page.dart';
import '../ui/booking/confirm_booking_page.dart';
import '../ui/cart/cart_page.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _suscripcion;

  _GoRouterRefreshStream(Stream flujo) {
    _suscripcion = flujo.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}

GoRouter construirEnrutador({GlobalKey<NavigatorState>? navigatorKey}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      // ProveedorAuth.perfil (no la sesión cruda de Supabase): una cuenta
      // real de OTRO negocio queda con sesión de Supabase viva por un
      // instante hasta que _validarTenant() la cierra — si esta guarda
      // usara auth.currentUser directo, esa ventana dejaría pasar a
      // /booking/* con una identidad que no pertenece a este dominio.
      final estaConectado = context.read<ProveedorAuth>().perfil != null;
      final enPaginaAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // Si está conectado y quiere ir al login/registro → mandarlo al inicio
      if (estaConectado && enPaginaAuth) return '/';
      // Rutas de reserva requieren auth
      if (!estaConectado && state.matchedLocation.startsWith('/booking')) return '/';
      // Todo lo demás (incluido '/' sin login) es permitido
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const PaginaLogin()),
      GoRoute(path: '/register', builder: (_, __) => const PaginaRegistro()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const PaginaOlvideContrasena()),
      GoRoute(path: '/', builder: (_, __) => const CarcasaApp()),

      // Flujo de reserva (3 pasos: servicio → fecha/hora/especialista → confirmar) — con guards para evitar saltar pasos
      GoRoute(
        path: '/booking/service',
        builder: (_, __) => const PaginaSeleccionarServicio(),
      ),
      GoRoute(
        path: '/booking/slot',
        redirect: (context, state) {
          final reserva = context.read<ProveedorReserva>();
          if (reserva.serviciosSeleccionados.isEmpty) return '/booking/service';
          return null;
        },
        builder: (_, __) => const PaginaSeleccionarTurno(),
      ),
      GoRoute(
        path: '/booking/confirm',
        redirect: (context, state) {
          final reserva = context.read<ProveedorReserva>();
          if (reserva.serviciosSeleccionados.isEmpty) return '/booking/service';
          if (reserva.empleadoSeleccionado == null) return '/booking/slot';
          if (reserva.turnoSeleccionado == null) return '/booking/slot';
          return null;
        },
        builder: (_, __) => const PaginaConfirmarReserva(),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const PaginaCarrito()),
    ],
  );
}
