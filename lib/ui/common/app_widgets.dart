import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

// ── Botón primario ─────────────────────────────────────────────
class BotonPrincipal extends StatelessWidget {
  final String etiqueta;
  final VoidCallback? onPressed;
  final bool cargando;
  final IconData? icono;

  const BotonPrincipal({
    super.key,
    required this.etiqueta,
    this.onPressed,
    this.cargando = false,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        child: cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : icono != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(icono, size: 18), const SizedBox(width: 8), Text(etiqueta)],
                  )
                : Text(etiqueta),
      ),
    );
  }
}

// ── Campo de texto ─────────────────────────────────────────────
class CampoTexto extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final bool ocultar;
  final TextInputType? tipoTeclado;
  final String? Function(String?)? validador;
  final Widget? prefijo;
  final Widget? sufijo;
  final int maxLineas;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.ocultar = false,
    this.tipoTeclado,
    this.validador,
    this.prefijo,
    this.sufijo,
    this.maxLineas = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: ocultar,
      keyboardType: tipoTeclado,
      validator: validador,
      maxLines: maxLineas,
      style: const TextStyle(color: kText),
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: prefijo,
        suffixIcon: sufijo,
      ),
    );
  }
}

// ── Avatar de red ──────────────────────────────────────────────
class AvatarRed extends StatelessWidget {
  final String? url;
  final double radio;
  final String? nombre;

  const AvatarRed({super.key, this.url, this.radio = 24, this.nombre});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radio,
        backgroundImage: CachedNetworkImageProvider(url!),
        backgroundColor: kDivider,
      );
    }
    return CircleAvatar(
      radius: radio,
      backgroundColor: kPrimary.withOpacity(0.2),
      child: Text(
        (nombre?.isNotEmpty == true ? nombre![0] : '?').toUpperCase(),
        style: TextStyle(
          color: kPrimary,
          fontSize: radio * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Chip de estado ─────────────────────────────────────────────
class ChipEstado extends StatelessWidget {
  final String etiqueta;
  final Color color;

  const ChipEstado({super.key, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(etiqueta, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: Color(0xFFAEAEB2)),
          const SizedBox(height: 16),
          Text(titulo, style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 16)),
          if (subtitulo != null) ...[
            const SizedBox(height: 8),
            Text(subtitulo!, style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ── Card de sección ────────────────────────────────────────────
class TarjetaSeccion extends StatelessWidget {
  final Widget child;
  final EdgeInsets? relleno;

  const TarjetaSeccion({super.key, required this.child, this.relleno});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: relleno ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
        boxShadow: const [
          BoxShadow(color: kShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────
class TarjetaEstadistica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color? color;

  const TarjetaEstadistica({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
        boxShadow: const [
          BoxShadow(color: kShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: c, size: 28),
          const SizedBox(height: 12),
          Text(valor,
              style: TextStyle(
                  color: kText, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(etiqueta, style: const TextStyle(color: kTextSub, fontSize: 12)),
        ],
      ),
    );
  }
}
