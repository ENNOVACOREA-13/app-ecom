import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

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

  Future<void> _mostrarDialogoServicio({ModeloServicio? existente}) async {
    final ctrlNombre = TextEditingController(text: existente?.nombre);
    final ctrlDesc = TextEditingController(text: existente?.descripcion);
    final ctrlPrecio = TextEditingController(
        text: existente?.precio.toStringAsFixed(0));
    final ctrlDuracion = TextEditingController(
        text: existente?.duracionMin.toString());
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existente == null ? 'Nuevo servicio' : 'Editar servicio',
        ),
        content: Form(
          key: claveFormulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ctrlNombre,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrlDesc,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrlPrecio,
                  style: const TextStyle(color: kText),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio *'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrlDuracion,
                  style: const TextStyle(color: kText),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duración (minutos) *'),
                  validator: (v) {
                    if (int.tryParse(v ?? '') == null) return 'Número inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (claveFormulario.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(existente == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );

    if (exito == true && mounted) {
      final proveedor = context.read<ProveedorServicio>();
      if (existente == null) {
        await proveedor.crearServicio(ModeloServicio(
          id: '',
          nombre: ctrlNombre.text.trim(),
          descripcion: ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
          duracionMin: int.parse(ctrlDuracion.text),
          precio: double.parse(ctrlPrecio.text),
          estaActivo: true,
        ));
      } else {
        await proveedor.actualizarServicio(existente.id, {
          'name': ctrlNombre.text.trim(),
          'description': ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
          'duration_min': int.parse(ctrlDuracion.text),
          'price': double.parse(ctrlPrecio.text),
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
      appBar: AppBar(title: const Text('Gestionar Servicios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoServicio(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: proveedor.cargando
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
                    return Container(
                      decoration: const BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        boxShadow: kNeumorphicShadowsSmall,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: s.estaActivo
                                ? kPrimaryLight
                                : kTextMuted.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.content_cut,
                              color: s.estaActivo ? kPrimary : kTextMuted, size: 20),
                        ),
                        title: Text(s.nombre,
                            style: TextStyle(
                                color: s.estaActivo ? kText : kTextMuted,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${s.etiquetaDuracion} · \$${s.precio.toStringAsFixed(0)}',
                            style: const TextStyle(color: kTextMuted, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: kTextSub,
                              onPressed: () => _mostrarDialogoServicio(existente: s),
                            ),
                            IconButton(
                              icon: Icon(
                                s.estaActivo ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              color: kTextSub,
                              onPressed: () => proveedor.actualizarServicio(s.id, {'is_active': !s.estaActivo}),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
