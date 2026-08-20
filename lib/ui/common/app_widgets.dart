import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/config_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_page.dart';

// ── Botón "Cargar más" (pie de lista paginada) ──────────────────
class BotonCargarMas extends StatelessWidget {
  final bool cargando;
  final VoidCallback onTap;
  const BotonCargarMas({super.key, required this.cargando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: cargando
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton(
                onPressed: onTap,
                child: const Text('Cargar más'),
              ),
      ),
    );
  }
}

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
  final TextInputAction? accionTeclado;
  final void Function(String)? alEnviar;

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
    this.accionTeclado,
    this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: ocultar,
      keyboardType: tipoTeclado,
      validator: validador,
      maxLines: maxLineas,
      textInputAction: accionTeclado,
      onFieldSubmitted: alEnviar,
      // Solo texto plano: evita pegar imágenes u otro contenido enriquecido
      // que el portapapeles pudiera traer junto con el texto (no aplica a
      // campos multilínea como bio/descripción).
      inputFormatters: maxLineas == 1
          ? [FilteringTextInputFormatter.singleLineFormatter]
          : null,
      style: const TextStyle(color: Color(0xFF1C1C1E)),
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

  Widget _inicial(BuildContext context) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: context.colorPrimario.withOpacity(0.2),
      child: Text(
        (nombre?.isNotEmpty == true ? nombre![0] : '?').toUpperCase(),
        style: TextStyle(
          color: context.colorPrimario,
          fontSize: radio * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _inicial(context);

    // Image.network (no CachedNetworkImageProvider) para tener errorBuilder:
    // si una carga falla una vez (blip de red), muestra la inicial en vez
    // de quedarse en un círculo negro permanente sin reintentar nunca.
    return ClipOval(
      child: SizedBox(
        width: radio * 2,
        height: radio * 2,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: kDivider,
              alignment: Alignment.center,
              child: SizedBox(
                width: radio * 0.7,
                height: radio * 0.7,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _inicial(context),
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
    final cfg = context.watch<ProveedorConfig>();
    return Container(
      width: double.infinity,
      padding: relleno ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cfg.radioContenedorEfectivo),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05 * cfg.sombraContenedorEfectiva),
            blurRadius: 8 * cfg.sombraContenedorEfectiva,
            offset: const Offset(0, 2),
          ),
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
    final c = color ?? context.colorPrimario;
    final cfg = context.watch<ProveedorConfig>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cfg.radioContenedorEfectivo),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05 * cfg.sombraContenedorEfectiva),
            blurRadius: 8 * cfg.sombraContenedorEfectiva,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: c, size: 28),
          const SizedBox(height: 12),
          Text(valor,
              style: const TextStyle(
                  color: Color(0xFF1C1C1E), fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(etiqueta, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Campanita de notificaciones (con contador) ─────────────────
class IconoNotificaciones extends StatelessWidget {
  final Color color;
  const IconoNotificaciones({super.key, this.color = const Color(0xFF1C1C1E)});

  @override
  Widget build(BuildContext context) {
    final noLeidas = context.watch<ProveedorNotificaciones>().noLeidas;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaginaNotificaciones()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: color, size: 26),
          if (noLeidas > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  noLeidas > 9 ? '9+' : '$noLeidas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tarjeta presionable: envuelve cualquier widget tocable con feedback
// de escala (0.97) al presionar, siguiendo la skill de Emil Kowalski —
// "buttons must feel responsive". No usar onTap del AnimatedScale
// directamente para no interferir con el hijo.
class TarjetaPresionable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  const TarjetaPresionable({super.key, required this.child, this.onTap, this.behavior});

  @override
  State<TarjetaPresionable> createState() => _TarjetaPresionableState();
}

class _TarjetaPresionableState extends State<TarjetaPresionable> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Fila de opción: ícono en círculo + título/subtítulo + flecha ──────
class FilaOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const FilaOpcion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaPresionable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kNeumorphicShadowsSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorPrimario.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: context.colorPrimario, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitulo,
                      style: const TextStyle(color: kTextMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextMuted),
          ],
        ),
      ),
    );
  }
}

// ── Perforación de ticket: línea punteada con muescas circulares ──────
// (el "corte" clásico de un recibo entre secciones de una tarjeta blanca)
class PerforacionTicket extends StatelessWidget {
  const PerforacionTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: _LineaPunteadaTicket()),
          Positioned(left: -12, top: -12, child: _MuescaTicket(radio: 12)),
          Positioned(right: -12, top: -12, child: _MuescaTicket(radio: 12)),
        ],
      ),
    );
  }
}

class _LineaPunteadaTicket extends StatelessWidget {
  const _LineaPunteadaTicket();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const anchoGuion = 6.0;
        const espacio = 5.0;
        final cantidad = (constraints.maxWidth / (anchoGuion + espacio)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            cantidad,
            (_) => Container(width: anchoGuion, height: 1.5, color: const Color(0xFFD1D1D6)),
          ),
        );
      },
    );
  }
}

class _MuescaTicket extends StatelessWidget {
  final double radio;
  const _MuescaTicket({required this.radio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radio * 2,
      height: radio * 2,
      decoration: const BoxDecoration(color: Color(0xFFF2F2F7), shape: BoxShape.circle),
    );
  }
}

// ── Píldora ovalada: precio + botón circular de agregar al carrito ───
class PildoraPrecioCarrito extends StatelessWidget {
  final String precio;
  final String? precioTachado;
  final bool sinStock;
  final VoidCallback? onTap;

  const PildoraPrecioCarrito({
    super.key,
    required this.precio,
    this.precioTachado,
    required this.sinStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: 18, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (precioTachado != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(precioTachado!,
                    style: const TextStyle(
                        color: Color(0xFFAEAEB2),
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough)),
              ),
            Text(precio,
                style: const TextStyle(
                    color: Color(0xFF1C1C1E), fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 14),
            TarjetaPresionable(
              onTap: onTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: sinStock ? Colors.black26 : const Color(0xFF1C1C1E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
