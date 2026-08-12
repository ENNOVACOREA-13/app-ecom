import 'package:flutter/material.dart';

/// Envuelve un ítem de lista/grid con una entrada animada (fade + slide-up),
/// con un pequeño retraso escalonado según [index] para un efecto de cascada.
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

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacidad = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _desplazamiento = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(position: _desplazamiento, child: widget.child),
    );
  }
}
