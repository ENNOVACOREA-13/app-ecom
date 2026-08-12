import 'package:flutter/material.dart';

/// Animación de "volar" un producto hacia el ícono del carrito al agregarlo.
class AnimacionCarrito {
  AnimacionCarrito._();

  static void volar({
    required BuildContext contextOrigen,
    GlobalKey? destinoKey,
    String? imagenUrl,
  }) {
    final overlayState = Overlay.maybeOf(contextOrigen);
    if (overlayState == null) return;
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    final origenBox = contextOrigen.findRenderObject() as RenderBox?;
    if (overlayBox == null || origenBox == null) return;

    final origenPos = origenBox.localToGlobal(
      origenBox.size.center(Offset.zero),
      ancestor: overlayBox,
    );

    Offset destinoPos;
    final destinoBox =
        destinoKey?.currentContext?.findRenderObject() as RenderBox?;
    if (destinoBox != null) {
      destinoPos = destinoBox.localToGlobal(
        destinoBox.size.center(Offset.zero),
        ancestor: overlayBox,
      );
    } else {
      // Sin ícono de carrito visible en esta pantalla: vuela hacia la
      // esquina superior derecha como destino genérico.
      destinoPos = Offset(overlayBox.size.width - 30, 60);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ItemVolador(
        inicio: origenPos,
        fin: destinoPos,
        imagenUrl: imagenUrl,
        alTerminar: () => entry.remove(),
      ),
    );
    overlayState.insert(entry);
  }
}

class _ItemVolador extends StatefulWidget {
  final Offset inicio;
  final Offset fin;
  final String? imagenUrl;
  final VoidCallback alTerminar;

  const _ItemVolador({
    required this.inicio,
    required this.fin,
    required this.imagenUrl,
    required this.alTerminar,
  });

  @override
  State<_ItemVolador> createState() => _ItemVoladorState();
}

class _ItemVoladorState extends State<_ItemVolador>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curva;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _curva = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    _controller.forward().whenComplete(widget.alTerminar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tamano = 42.0;
    return AnimatedBuilder(
      animation: _curva,
      builder: (context, _) {
        final t = _curva.value;
        final dx = widget.inicio.dx + (widget.fin.dx - widget.inicio.dx) * t;
        final arco = -90 * (4 * t * (1 - t));
        final dy = widget.inicio.dy + (widget.fin.dy - widget.inicio.dy) * t + arco;
        final escala = 1.0 - (t * 0.55);
        final opacidad = t < 0.85 ? 1.0 : (1 - t) / 0.15;

        return Positioned(
          left: dx - tamano / 2,
          top: dy - tamano / 2,
          child: Opacity(
            opacity: opacidad.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: escala,
              child: Container(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                  image: (widget.imagenUrl != null && widget.imagenUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(widget.imagenUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: (widget.imagenUrl == null || widget.imagenUrl!.isEmpty)
                    ? const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF1C1C1E))
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
