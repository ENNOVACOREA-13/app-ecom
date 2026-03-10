import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/auth/login_page.dart';
import '../ui/auth/register_page.dart';
import '../ui/shell/app_shell.dart';
import '../ui/booking/select_service_page.dart';
import '../ui/booking/select_employee_page.dart';
import '../ui/booking/select_slot_page.dart';
import '../ui/booking/confirm_booking_page.dart';

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

GoRouter construirEnrutador() {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final estaConectado = Supabase.instance.client.auth.currentUser != null;
      final enPaginaAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!estaConectado && !enPaginaAuth) return '/login';
      if (estaConectado && enPaginaAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const PaginaLogin()),
      GoRoute(path: '/register', builder: (_, __) => const PaginaRegistro()),
      GoRoute(path: '/', builder: (_, __) => const CarcasaApp()),

      // Flujo de reserva (4 pasos)
      GoRoute(path: '/booking/service', builder: (_, __) => const PaginaSeleccionarServicio()),
      GoRoute(path: '/booking/employee', builder: (_, __) => const PaginaSeleccionarEmpleado()),
      GoRoute(path: '/booking/slot', builder: (_, __) => const PaginaSeleccionarTurno()),
      GoRoute(path: '/booking/confirm', builder: (_, __) => const PaginaConfirmarReserva()),
    ],
  );
}
