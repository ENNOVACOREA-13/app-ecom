import 'package:flutter/material.dart';

/// Caja con shimmer animado (gradiente que se desliza), para usarse en
/// lugar de un spinner bloqueante cuando el contenido que va a cargar
/// es una forma predecible (una línea de texto, un avatar, una imagen).
class CajaEsqueleto extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  const CajaEsqueleto({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<CajaEsqueleto> createState() => _CajaEsqueletoState();
}

class _CajaEsqueletoState extends State<CajaEsqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(_controller.value * 3, 0),
              colors: const [
                Color(0xFFF2F2F7),
                Color(0xFFE5E5EA),
                Color(0xFFF2F2F7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Fila esqueleto del tamaño típico de una tarjeta de lista: avatar/imagen
/// a la izquierda + dos líneas de texto a la derecha.
class _FilaEsqueleto extends StatelessWidget {
  const _FilaEsqueleto();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CajaEsqueleto(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CajaEsqueleto(height: 14, width: 160),
                const SizedBox(height: 8),
                CajaEsqueleto(height: 12, width: MediaQuery.of(context).size.width * 0.3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de N filas esqueleto, para reemplazar un spinner de página
/// completa mientras carga una lista de tarjetas uniformes.
class ListaEsqueleto extends StatelessWidget {
  final int cantidad;
  final EdgeInsetsGeometry padding;
  const ListaEsqueleto({
    super.key,
    this.cantidad = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: cantidad,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _FilaEsqueleto(),
    );
  }
}
