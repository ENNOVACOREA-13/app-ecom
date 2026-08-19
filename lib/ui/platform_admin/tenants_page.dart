import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/tenant.dart';
import '../../providers/tenant_provider.dart';

class PaginaNegocios extends StatefulWidget {
  const PaginaNegocios({super.key});

  @override
  State<PaginaNegocios> createState() => _PaginaNegociosState();
}

class _PaginaNegociosState extends State<PaginaNegocios> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorTenants>().cargarTenants();
    });
  }

  Future<void> _mostrarDialogoNuevoNegocio() async {
    final ctrlSlug = TextEditingController();
    final ctrlNombre = TextEditingController();
    bool guardando = false;
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Nuevo negocio', style: TextStyle(color: Color(0xFF1C1C1E))),
          content: Form(
            key: claveFormulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ctrlNombre,
                  autofocus: true,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Nombre del negocio',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrlSlug,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Slug (identificador corto, ej. mi-barberia)',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa un slug';
                    if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(v.trim())) {
                      return 'Solo minúsculas, números y guiones';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.colorPrimario),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!claveFormulario.currentState!.validate()) return;
                      setLocal(() => guardando = true);
                      final ok = await context.read<ProveedorTenants>().crearTenant(
                            slug: ctrlSlug.text.trim(),
                            businessName: ctrlNombre.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx, ok);
                    },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    final error = context.read<ProveedorTenants>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exito == true ? 'Negocio creado' : (error ?? 'No se pudo crear el negocio')),
        backgroundColor: exito == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _mostrarDialogoDominio(Tenant tenant) async {
    final ctrlDominio = TextEditingController();
    bool guardando = false;
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Agregar dominio a ${tenant.businessName}',
              style: const TextStyle(color: Color(0xFF1C1C1E))),
          content: Form(
            key: claveFormulario,
            child: TextFormField(
              controller: ctrlDominio,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF1C1C1E)),
              decoration: InputDecoration(
                labelText: 'Dominio (ej. mi-barberia.vercel.app)',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un dominio' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.colorPrimario),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!claveFormulario.currentState!.validate()) return;
                      setLocal(() => guardando = true);
                      final ok = await context
                          .read<ProveedorTenants>()
                          .agregarDominio(tenant.id, ctrlDominio.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx, ok);
                    },
              child: const Text('Agregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    final error = context.read<ProveedorTenants>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exito == true ? 'Dominio agregado' : (error ?? 'No se pudo agregar el dominio')),
        backgroundColor: exito == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _confirmarQuitarDominio(TenantDomain dominio) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Quitar dominio', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: Text('¿Quitar "${dominio.domain}"? Ese dominio dejará de resolver a este negocio.',
            style: const TextStyle(color: Color(0xFF6E6E73))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ProveedorTenants>().eliminarDominio(dominio.id);
    }
  }

  Future<void> _alternarStatus(Tenant tenant) async {
    final nuevoStatus = tenant.estaActivo ? 'suspended' : 'active';
    await context.read<ProveedorTenants>().actualizarStatus(tenant.id, nuevoStatus);
  }

  Color _colorStatus(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _etiquetaStatus(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'maintenance':
        return 'Mantenimiento';
      default:
        return 'Suspendido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorTenants>();
    final tenants = prov.tenants;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Negocios')),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoNegocio,
        backgroundColor: context.colorPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => context.read<ProveedorTenants>().cargarTenants(),
            child: prov.cargando && tenants.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : tenants.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                        children: const [
                          Center(
                            child: Text('Sin negocios todavía — crea el primero con el botón +',
                                style: TextStyle(color: kTextSub)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: tenants.length,
                        itemBuilder: (context, i) {
                          final t = tenants[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E5EA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.businessName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Color(0xFF1C1C1E))),
                                          Text(t.slug,
                                              style: const TextStyle(
                                                  fontSize: 12, color: kTextSub)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _colorStatus(t.status).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(_etiquetaStatus(t.status),
                                          style: TextStyle(
                                              color: _colorStatus(t.status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Color(0xFF8E8E93)),
                                      onSelected: (accion) {
                                        if (accion == 'dominio') _mostrarDialogoDominio(t);
                                        if (accion == 'status') _alternarStatus(t);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'dominio',
                                            child: Row(children: [
                                              Icon(Icons.language, size: 18),
                                              SizedBox(width: 8),
                                              Text('Agregar dominio'),
                                            ])),
                                        PopupMenuItem(
                                            value: 'status',
                                            child: Row(children: [
                                              Icon(
                                                  t.estaActivo
                                                      ? Icons.pause_circle_outline
                                                      : Icons.play_circle_outline,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(t.estaActivo ? 'Suspender' : 'Reactivar'),
                                            ])),
                                      ],
                                    ),
                                  ],
                                ),
                                if (t.dominios.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: t.dominios
                                        .map((d) => InputChip(
                                              label: Text(d.domain, style: const TextStyle(fontSize: 12)),
                                              backgroundColor: const Color(0xFFF2F2F7),
                                              onDeleted: () => _confirmarQuitarDominio(d),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
