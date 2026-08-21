import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';

/// Banda tipo carrusel, siempre arriba de la app, editable desde sysadmin
/// (ver PaginaDisenadorVista) — de derecha a izquierda en ciclo continuo.
class BandaAnuncio extends StatelessWidget {
  const BandaAnuncio({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ProveedorConfig>();
    if (!cfg.bandaHabilitada || cfg.bandaTexto.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 32,
      color: cfg.bandaColorFondo,
      child: Marquee(
        text: cfg.bandaTexto,
        style: TextStyle(
          color: cfg.bandaColorTexto,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        blankSpace: 60,
        velocity: 40,
        pauseAfterRound: const Duration(seconds: 1),
      ),
    );
  }
}
