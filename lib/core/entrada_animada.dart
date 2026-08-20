import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Envuelve un ítem de lista/grid con una entrada animada (fade + slide-up),
/// con un pequeño retraso escalonado según [index] para un efecto de cascada.
///
/// Se dispara cuando el ítem realmente ENTRA al viewport (vía
/// VisibilityDetector), no cuando se construye — en listas largas (sobre
/// todo las que usan shrinkWrap: true dentro de otro scroll) Flutter puede
/// construir muchos ítems de una sola vez aunque estén fuera de pantalla,
/// así que animar en initState() hacía que la cascada se "gastara" toda de
/// golpe al cargar y no se viera nada al hacer scroll más abajo.
class EntradaAnimada extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPorItem;

  const EntradaAnimada({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPorItem = const Duration(milliseconds: 40),
  });

  @override
  State<EntradaAnimada> createState() => _EntradaAnimadaState();
}

class _EntradaAnimadaState extends State<EntradaAnimada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacidad;
  late final Animation<Offset> _desplazamiento;
  late final Key _claveVisibilidad;
  bool _yaSeDisparo = false;

  @override
  void initState() {
    super.initState();
    // Un ValueKey propio (no el del widget) porque VisibilityDetector
    // necesita una key ÚNICA por instancia visible en pantalla a la vez —
    // usar widget.key podría repetirse o venir null.
    _claveVisibilidad = UniqueKey();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacidad = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _desplazamiento = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _alCambiarVisibilidad(VisibilityInfo info) {
    if (_yaSeDisparo || info.visibleFraction <= 0 || !mounted) return;
    _yaSeDisparo = true;
    final retraso = widget.delayPorItem * widget.index.clamp(0, 12);
    Future.delayed(retraso, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _claveVisibilidad,
      onVisibilityChanged: _alCambiarVisibilidad,
      child: FadeTransition(
        opacity: _opacidad,
        child: SlideTransition(position: _desplazamiento, child: widget.child),
      ),
    );
  }
}
