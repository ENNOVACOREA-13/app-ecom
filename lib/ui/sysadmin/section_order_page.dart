import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/config_provider.dart';

const Map<String, ({String etiqueta, IconData icono})> _kEtiquetasSeccion = {
  'chips_categorias': (etiqueta: 'Chips de categorías (tienda)', icono: Icons.apps_rounded),
  'banner_hero': (etiqueta: 'Banner principal (reservar)', icono: Icons.content_cut),
  'categorias': (etiqueta: 'Categorías de Servicios', icono: Icons.content_cut),
  'banner_promo': (etiqueta: 'Banner promocional', icono: Icons.image_outlined),
  'productos': (etiqueta: 'Productos Populares', icono: Icons.shopping_bag_outlined),
};

class PaginaOrdenSecciones extends StatefulWidget {
  const PaginaOrdenSecciones({super.key});

  @override
  State<PaginaOrdenSecciones> createState() => _PaginaOrdenSeccionesState();
}

class _PaginaOrdenSeccionesState extends State<PaginaOrdenSecciones> {
  late List<Map<String, dynamic>> _secciones;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _secciones = context
        .read<ProveedorConfig>()
        .seccionesHomeBorrador
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final exito = await context.read<ProveedorConfig>().actualizarBorradorSecciones(_secciones);
    if (mounted) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(exito ? 'Orden guardado en el borrador' : 'Error al guardar'),
        backgroundColor: exito ? Colors.green : Colors.red,
      ));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _secciones.removeAt(oldIndex);
      _secciones.insert(newIndex, item);
    });
    _guardar();
  }

  void _toggleVisible(int index, bool valor) {
    setState(() => _secciones[index]['visible'] = valor);
    _guardar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Orden de secciones'),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Arrastra para reordenar y usa el switch para mostrar u ocultar cada sección '
                'en la pantalla de inicio. '
                'Los cambios se guardan como borrador — usa "Publicar cambios" en Diseñador '
                'de vista para que los vean los clientes reales.',
                style: TextStyle(fontSize: 12, color: const Color(0xFF8E8E93)),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: _secciones.length,
                buildDefaultDragHandles: false,
                onReorder: _onReorder,
                itemBuilder: (context, i) {
                  final s = _secciones[i];
                  final key = s['key'] as String;
                  final visible = s['visible'] as bool? ?? true;
                  final info = _kEtiquetasSeccion[key];
                  return EntradaAnimada(
                    key: ValueKey(key),
                    index: i,
                    child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.drag_handle_rounded,
                                      color: Color(0xFF8E8E93)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: context.colorPrimario.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(info?.icono ?? Icons.widgets_outlined,
                                        color: context.colorPrimario, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      info?.etiqueta ?? key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: visible
                                            ? const Color(0xFF1C1C1E)
                                            : const Color(0xFFAEAEB2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Switch(
                            value: visible,
                            activeColor: context.colorPrimario,
                            onChanged: (v) => _toggleVisible(i, v),
                          ),
                        ),
                      ],
                    ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
