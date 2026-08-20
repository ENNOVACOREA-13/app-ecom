import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../data/user_provisioning_service.dart';
import '../../domain/models/tenant.dart';
import '../../providers/tenant_provider.dart';
import '../common/toast.dart';

class PaginaNegocios extends StatefulWidget {
  const PaginaNegocios({super.key});

  @override
  State<PaginaNegocios> createState() => _PaginaNegociosState();
}

class _PaginaNegociosState extends State<PaginaNegocios> {
  final _servicioAlta = ServicioAltaUsuarios();

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
    mostrarToast(
      context,
      exito == true ? 'Negocio creado' : (error ?? 'No se pudo crear el negocio'),
      tipo: exito == true ? TipoToast.exito : TipoToast.error,
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
    mostrarToast(
      context,
      exito == true ? 'Dominio agregado' : (error ?? 'No se pudo agregar el dominio'),
      tipo: exito == true ? TipoToast.exito : TipoToast.error,
    );
  }

  Future<void> _mostrarDialogoInvitarAdmin(Tenant tenant, String role) async {
    final ctrlNombre = TextEditingController();
    final ctrlEmail = TextEditingController();
    bool guardando = false;
    String? errorInvitacion;
    final claveFormulario = GlobalKey<FormState>();
    final etiquetaRol = role == 'sysadmin' ? 'sysadmin' : 'administrador';

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Invitar $etiquetaRol a ${tenant.businessName}',
              style: const TextStyle(color: Color(0xFF1C1C1E))),
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
                    labelText: 'Nombre completo',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrlEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Se le manda un correo de invitación para que configure su propia contraseña.',
                  style: TextStyle(fontSize: 12, color: kTextSub),
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
                      var ok = true;
                      try {
                        await _servicioAlta.invitarUsuario(
                          email: ctrlEmail.text.trim(),
                          fullName: ctrlNombre.text.trim(),
                          role: role,
                          tenantId: tenant.id,
                        );
                      } catch (e) {
                        ok = false;
                        errorInvitacion = mapearErrorInvitacion(e.toString());
                      }
                      if (ctx.mounted) Navigator.pop(ctx, ok);
                    },
              child: const Text('Invitar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    mostrarToast(
      context,
      exito == true ? 'Invitación enviada' : (errorInvitacion ?? 'No se pudo enviar la invitación'),
      tipo: exito == true ? TipoToast.exito : TipoToast.error,
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

  Future<void> _mostrarDialogoEditarAdmin(CuentaAdminTenant cuenta) async {
    final ctrlNombre = TextEditingController(text: cuenta.nombreCompleto ?? '');
    final ctrlTelefono = TextEditingController(text: cuenta.telefono ?? '');
    bool guardando = false;
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Editar ${cuenta.email ?? cuenta.id}',
              style: const TextStyle(color: Color(0xFF1C1C1E))),
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
                    labelText: 'Nombre completo',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrlTelefono,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
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
                      final ok = await context.read<ProveedorTenants>().editarPerfilAdmin(
                            userId: cuenta.id,
                            nombre: ctrlNombre.text.trim(),
                            telefono:
                                ctrlTelefono.text.trim().isEmpty ? null : ctrlTelefono.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx, ok);
                    },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    final error = context.read<ProveedorTenants>().error;
    mostrarToast(
      context,
      exito == true ? 'Cambios guardados' : (error ?? 'No se pudo guardar'),
      tipo: exito == true ? TipoToast.exito : TipoToast.error,
    );
  }

  Future<void> _confirmarEliminarCuentaAdmin(CuentaAdminTenant cuenta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar cuenta', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: Text(
            '¿Eliminar por completo la cuenta de "${cuenta.email ?? cuenta.id}"? '
            'Se borra su perfil y su acceso — si quiere volver, tiene que '
            'registrarse de nuevo. Sus reservas/pedidos/comisiones anteriores '
            'se conservan, sin ligar a ninguna cuenta. Esta acción no se puede deshacer.',
            style: const TextStyle(color: Color(0xFF6E6E73))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final exito = await context.read<ProveedorTenants>().eliminarPerfilAdmin(cuenta.id);
    if (!mounted) return;
    final error = context.read<ProveedorTenants>().error;
    mostrarToast(
      context,
      exito ? 'Cuenta eliminada' : (error ?? 'No se pudo eliminar la cuenta'),
      tipo: exito ? TipoToast.exito : TipoToast.error,
    );
  }

  Future<void> _confirmarQuitarAcceso(Tenant tenant, CuentaAdminTenant cuenta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Quitar acceso', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: Text(
            '¿Quitarle a "${cuenta.email ?? cuenta.id}" el acceso a ${tenant.businessName}? '
            'Sigue pudiendo entrar a su negocio de casa, solo pierde este.',
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
      await context
          .read<ProveedorTenants>()
          .eliminarMembresia(userId: cuenta.id, tenantId: tenant.id);
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
                          return EntradaAnimada(
                            index: i,
                            child: Container(
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
                                        if (accion == 'admin') {
                                          _mostrarDialogoInvitarAdmin(t, 'admin');
                                        }
                                        if (accion == 'sysadmin') {
                                          _mostrarDialogoInvitarAdmin(t, 'sysadmin');
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'dominio',
                                            child: Row(children: [
                                              Icon(Icons.language, size: 18),
                                              SizedBox(width: 8),
                                              Text('Agregar dominio'),
                                            ])),
                                        const PopupMenuItem(
                                            value: 'admin',
                                            child: Row(children: [
                                              Icon(Icons.admin_panel_settings_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Invitar administrador'),
                                            ])),
                                        const PopupMenuItem(
                                            value: 'sysadmin',
                                            child: Row(children: [
                                              Icon(Icons.shield_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Invitar sysadmin'),
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
                                if (t.admins.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFE5E5EA)),
                                  const SizedBox(height: 10),
                                  const Text('Cuentas administrativas',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kTextSub)),
                                  const SizedBox(height: 6),
                                  ...t.admins.map((a) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          children: [
                                            Icon(
                                                a.rol == 'sysadmin'
                                                    ? Icons.shield_outlined
                                                    : Icons.admin_panel_settings_outlined,
                                                size: 14,
                                                color: kTextSub),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.nombreCompleto?.isNotEmpty == true
                                                        ? '${a.nombreCompleto} · ${a.email ?? ''}'
                                                        : (a.email ?? a.id),
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1C1C1E)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  // Mismo rol, mismo correo, pero el botón de basura
                                                  // hace cosas distintas según de dónde venga el
                                                  // acceso — sin esta etiqueta esa diferencia no se
                                                  // ve en la UI.
                                                  if (a.email == kEmailSysadminPrincipal)
                                                    const Text('Sysadmin principal (protegido)',
                                                        style: TextStyle(fontSize: 10, color: kTextSub))
                                                  else if (!a.esMembresiaExtra && a.rol == 'sysadmin')
                                                    const Text('Negocio de origen (las cuentas sysadmin no se eliminan)',
                                                        style: TextStyle(fontSize: 10, color: kTextSub))
                                                  else if (!a.esMembresiaExtra)
                                                    const Text('Negocio de origen (se puede eliminar la cuenta)',
                                                        style: TextStyle(fontSize: 10, color: kTextSub)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF2F2F7),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                a.rol == 'sysadmin' ? 'sysadmin' : 'admin',
                                                style: const TextStyle(fontSize: 10, color: kTextSub),
                                              ),
                                            ),
                                            if (a.email != kEmailSysadminPrincipal) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined,
                                                    size: 16, color: kTextSub),
                                                tooltip: 'Editar nombre/teléfono',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _mostrarDialogoEditarAdmin(a),
                                              ),
                                            ],
                                            if (a.esMembresiaExtra &&
                                                a.email != kEmailSysadminPrincipal) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.close, size: 16, color: kTextSub),
                                                tooltip: 'Quitar acceso a este negocio',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _confirmarQuitarAcceso(t, a),
                                              ),
                                            ],
                                            if (!a.esMembresiaExtra &&
                                                a.rol != 'sysadmin' &&
                                                a.email != kEmailSysadminPrincipal) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline,
                                                    size: 16, color: Colors.red),
                                                tooltip: 'Eliminar esta cuenta',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _confirmarEliminarCuentaAdmin(a),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )),
                                ],
                              ],
                            ),
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
