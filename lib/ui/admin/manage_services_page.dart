import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../domain/models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../core/service_icons.dart';
import '../../data/ftp_upload_service.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';

class PaginaGestionServicios extends StatefulWidget {
  const PaginaGestionServicios({super.key});

  @override
  State<PaginaGestionServicios> createState() => _PaginaGestionServiciosState();
}

class _PaginaGestionServiciosState extends State<PaginaGestionServicios> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorServicio>().cargarServicios(esVistaAdmin: true);
    });
  }

  Future<String?> _elegirIcono(String? actual, Color colorVista) async {
    String consulta = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final resultados = buscarIconosServicio(consulta);
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Elige un icono',
                      style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    onChanged: (v) => setS(() => consulta = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar (ej. "corte", "barba", "spa")',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: resultados.isEmpty
                        ? const Center(
                            child: Text('Sin resultados', style: TextStyle(color: Color(0xFF8E8E93))))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: resultados.length,
                            itemBuilder: (_, i) {
                              final item = resultados[i];
                              final seleccionado = item.nombre == actual;
                              return GestureDetector(
                                onTap: () => Navigator.pop(ctx, item.nombre),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: seleccionado ? colorVista : const Color(0xFFF2F2F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icono,
                                      color: seleccionado ? Colors.white : const Color(0xFF6E6E73), size: 22),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Color?> _elegirColorPersonalizado(Color actual) async {
    Color temporal = actual;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Color personalizado', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temporal,
            onColorChanged: (c) => temporal = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, temporal),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoServicio({ModeloServicio? existente}) async {
    final ctrlNombre = TextEditingController(text: existente?.nombre);
    final ctrlDesc = TextEditingController(text: existente?.descripcion);
    final ctrlPrecio =
        TextEditingController(text: existente?.precio.toStringAsFixed(0));
    final ctrlDuracion =
        TextEditingController(text: existente?.duracionMin.toString());
    final claveFormulario = GlobalKey<FormState>();
    String? urlImagen = existente?.urlImagen;
    String? iconoNombre = existente?.iconoNombre;
    Color colorIcono = colorDesdeHex(existente?.iconoColor) ?? context.colorPrimario;
    bool subiendoImagen = false;

    final camposDecoracion = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
    );

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(existente == null ? 'Nuevo servicio' : 'Editar servicio',
              style: const TextStyle(color: Color(0xFF1C1C1E))),
          content: Form(
            key: claveFormulario,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selector de imagen ──────────────────
                  GestureDetector(
                    onTap: subiendoImagen
                        ? null
                        : () async {
                            setLocal(() => subiendoImagen = true);
                            final url = await ServicioFTP.seleccionarYSubirImagen(
                              nombreArchivo: ctrlNombre.text.trim(),
                              onError: (e) {
                                if (ctx.mounted) {
                                  mostrarToast(ctx, e, tipo: TipoToast.error);
                                }
                              },
                            );
                            if (ctx.mounted) {
                              setLocal(() {
                                subiendoImagen = false;
                                if (url != null) urlImagen = url;
                              });
                            }
                          },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: subiendoImagen
                          ? const Center(child: CircularProgressIndicator())
                          : urlImagen != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          urlImagen!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.broken_image_outlined,
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('Cambiar',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: Color(0xFF8E8E93), size: 28),
                                    SizedBox(height: 4),
                                    Text('Toca para añadir imagen',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xFF8E8E93), fontSize: 11)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Icono + color ────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final elegido = await _elegirIcono(iconoNombre, colorIcono);
                          if (elegido != null) setLocal(() => iconoNombre = elegido);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: colorIcono, shape: BoxShape.circle),
                          child: Icon(obtenerIconoServicio(iconoNombre),
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final elegido = await _elegirIcono(iconoNombre, colorIcono);
                            if (elegido != null) setLocal(() => iconoNombre = elegido);
                          },
                          child: const Text('Elegir icono',
                              style: TextStyle(color: Color(0xFF6E6E73), fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Color del icono',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...kColoresIconoServicio.map((c) {
                        final seleccionado = colorIcono.value == c.value;
                        return GestureDetector(
                          onTap: () => setLocal(() => colorIcono = c),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: seleccionado
                                  ? Border.all(color: const Color(0xFF1C1C1E), width: 2.5)
                                  : null,
                            ),
                            child: seleccionado
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () async {
                          final elegido = await _elegirColorPersonalizado(colorIcono);
                          if (elegido != null) setLocal(() => colorIcono = elegido);
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD1D1D6), width: 1.5),
                            gradient: const SweepGradient(colors: [
                              Colors.red, Colors.yellow, Colors.green,
                              Colors.cyan, Colors.blue, Colors.purple, Colors.red,
                            ]),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ctrlNombre,
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    decoration: camposDecoracion.copyWith(labelText: 'Nombre *'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ctrlDesc,
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    decoration: camposDecoracion.copyWith(labelText: 'Descripción'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ctrlPrecio,
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    keyboardType: TextInputType.number,
                    decoration: camposDecoracion.copyWith(labelText: 'Precio *'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ctrlDuracion,
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    keyboardType: TextInputType.number,
                    decoration: camposDecoracion.copyWith(labelText: 'Duración (minutos) *'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Número inválido';
                      if (n < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (claveFormulario.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(existente == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    if (exito == true && mounted) {
      final proveedor = context.read<ProveedorServicio>();
      final hexColor = colorAHex(colorIcono);
      if (existente == null) {
        await proveedor.crearServicio(ModeloServicio(
          id: '',
          nombre: ctrlNombre.text.trim(),
          descripcion:
              ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
          duracionMin: int.parse(ctrlDuracion.text),
          precio: double.parse(ctrlPrecio.text),
          urlImagen: urlImagen,
          estaActivo: true,
          iconoNombre: iconoNombre,
          iconoColor: hexColor,
        ));
      } else {
        await proveedor.actualizarServicio(existente.id, {
          'name': ctrlNombre.text.trim(),
          'description':
              ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
          'duration_min': int.parse(ctrlDuracion.text),
          'price': double.parse(ctrlPrecio.text),
          if (urlImagen != null) 'image_url': urlImagen,
          'icon_name': iconoNombre,
          'icon_color': hexColor,
        });
      }
    }

    ctrlNombre.dispose();
    ctrlDesc.dispose();
    ctrlPrecio.dispose();
    ctrlDuracion.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorServicio>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Servicios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoServicio(),
        backgroundColor: context.colorPrimario,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: EnvolturaResponsiva(
        child: proveedor.cargando
          ? const Center(child: CircularProgressIndicator())
          : proveedor.servicios.isEmpty
              ? const EstadoVacio(
                  icono: Icons.design_services_outlined,
                  titulo: 'Sin servicios',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: proveedor.servicios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = proveedor.servicios[i];
                    final colorIcono = colorDesdeHex(s.iconoColor) ?? context.colorPrimario;
                    final colorActivo = s.estaActivo ? colorIcono : const Color(0xFFC7C7CC);
                    return EntradaAnimada(
                      index: i,
                      child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _mostrarDialogoServicio(existente: s),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: colorActivo,
                                  shape: BoxShape.circle,
                                  boxShadow: s.estaActivo
                                      ? [BoxShadow(color: colorActivo.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                                      : null,
                                ),
                                child: Icon(obtenerIconoServicio(s.iconoNombre), color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: s.estaActivo ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93),
                                            fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF8E8E93)),
                                        const SizedBox(width: 3),
                                        Text(s.etiquetaDuracion,
                                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                        if (!s.estaActivo) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F2F7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Oculto',
                                                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorActivo.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('\$${s.precio.toStringAsFixed(0)}',
                                    style: TextStyle(color: colorActivo, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Color(0xFF8E8E93), size: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (accion) {
                                  if (accion == 'editar') _mostrarDialogoServicio(existente: s);
                                  if (accion == 'visibilidad') {
                                    proveedor.actualizarServicio(s.id, {'is_active': !s.estaActivo});
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1C1C1E)),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'visibilidad',
                                    child: Row(children: [
                                      Icon(s.estaActivo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 18, color: const Color(0xFF1C1C1E)),
                                      const SizedBox(width: 8),
                                      Text(s.estaActivo ? 'Ocultar' : 'Mostrar'),
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
