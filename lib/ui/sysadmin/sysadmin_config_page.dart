import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/activity_service.dart';
import '../../data/user_provisioning_service.dart';
import '../common/toast.dart';

class PaginaConfigSysadmin extends StatefulWidget {
  const PaginaConfigSysadmin({super.key});

  @override
  State<PaginaConfigSysadmin> createState() => PaginaConfigSysadminState();
}

class PaginaConfigSysadminState extends State<PaginaConfigSysadmin> {
  void recargar() => _cargar();
  final _client = Supabase.instance.client;
  final _servicioAlta = ServicioAltaUsuarios();
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;
  String _busqueda = '';

  static const _roles = ['client', 'employee', 'admin', 'super_admin', 'sysadmin'];

  @override
  void initState() {
    super.initState();
    _cargar();
    ServicioActividad.instancia.registrarPantalla('SysAdmin_Config');
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final datos = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      // Las cuentas sysadmin nunca se listan ni se editan desde aquí.
      setState(() => _usuarios = List<Map<String, dynamic>>.from(datos)
          .where((u) => u['role'] != 'sysadmin')
          .toList());
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error al cargar usuarios: $e', tipo: TipoToast.error);
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _usuarios;
    final q = _busqueda.toLowerCase();
    return _usuarios.where((u) {
      final nombre = (u['full_name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      return nombre.contains(q) || email.contains(q);
    }).toList();
  }

  // ── CREAR USUARIO ──────────────────────────────────────────
  Future<void> _crearUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String rolSel = 'client';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Nuevo usuario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),
                _Campo(ctrl: nombreCtrl, etiqueta: 'Nombre completo',
                    icono: Icons.person_outline),
                const SizedBox(height: 12),
                _Campo(ctrl: emailCtrl, etiqueta: 'Email',
                    icono: Icons.email_outlined,
                    tipo: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _Campo(ctrl: telCtrl, etiqueta: 'Teléfono (opcional)',
                    icono: Icons.phone_outlined,
                    tipo: TextInputType.phone),
                const SizedBox(height: 8),
                const Text(
                  'Se le manda un correo de invitación para que configure su propia contraseña.',
                  style: TextStyle(fontSize: 12, color: kTextSub),
                ),
                const SizedBox(height: 12),
                const Text('Rol', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _roles.map((r) => ChoiceChip(
                    label: Text(r),
                    selected: rolSel == r,
                    onSelected: (_) => setS(() => rolSel = r),
                    selectedColor: context.colorPrimario.withOpacity(0.2),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      final nombre = nombreCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final tel = telCtrl.text.trim();

                      if (nombre.isEmpty || email.isEmpty || !email.contains('@')) {
                        mostrarToast(ctx, 'Nombre y email son requeridos', tipo: TipoToast.error);
                        return;
                      }

                      Navigator.pop(ctx);
                      await _ejecutarCrearUsuario(
                          nombre: nombre, email: email,
                          telefono: tel, rol: rolSel);
                    },
                    child: const Text('Crear usuario',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _ejecutarCrearUsuario({
    required String nombre, required String email,
    required String telefono, required String rol,
  }) async {
    try {
      final idUsuario = await _servicioAlta.invitarUsuario(
        email: email, fullName: nombre, role: rol,
      );

      if (telefono.isNotEmpty) {
        await _client.from('profiles')
            .update({'phone': telefono}).eq('id', idUsuario);
      }

      if (mounted) {
        mostrarToast(context, 'Invitación enviada correctamente', tipo: TipoToast.exito);
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        mostrarToast(context, mapearErrorInvitacion(e.toString()), tipo: TipoToast.error);
      }
    }
  }

  // ── EDITAR USUARIO ─────────────────────────────────────────
  Future<void> _editarUsuario(Map<String, dynamic> u) async {
    final nombreCtrl = TextEditingController(text: u['full_name'] as String? ?? '');
    final telCtrl = TextEditingController(text: u['phone'] as String? ?? '');
    String rolSel = u['role'] as String? ?? 'client';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Editar usuario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),
                _Campo(ctrl: nombreCtrl, etiqueta: 'Nombre completo',
                    icono: Icons.person_outline),
                const SizedBox(height: 12),
                _Campo(ctrl: telCtrl, etiqueta: 'Teléfono',
                    icono: Icons.phone_outlined,
                    tipo: TextInputType.phone),
                const SizedBox(height: 12),
                const Text('Rol', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _roles.map((r) => ChoiceChip(
                    label: Text(r),
                    selected: rolSel == r,
                    onSelected: (_) => setS(() => rolSel = r),
                    selectedColor: context.colorPrimario.withOpacity(0.2),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await _client.from('profiles').update({
                          'full_name': nombreCtrl.text.trim(),
                          'phone': telCtrl.text.trim().isEmpty
                              ? null : telCtrl.text.trim(),
                          'role': rolSel,
                        }).eq('id', u['id']);
                        ServicioActividad.instancia.registrarFeature('editar_usuario');
                        _cargar();
                      } catch (e) {
                        if (mounted) {
                          mostrarToast(context, 'Error al guardar: $e', tipo: TipoToast.error);
                        }
                      }
                    },
                    child: const Text('Guardar cambios',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ELIMINAR USUARIO ───────────────────────────────────────
  Future<void> _eliminarUsuario(Map<String, dynamic> u) async {
    final nombre = u['full_name'] as String? ?? 'este usuario';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que quieres eliminar a "$nombre"?\n\n'
          'Se elimina su cuenta por completo (perfil y acceso) — si quiere '
          'volver, tiene que registrarse de nuevo. Sus reservas/pedidos/'
          'comisiones anteriores se conservan, sin ligar a ninguna cuenta.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _servicioAlta.eliminarUsuario(u['id'] as String);
        ServicioActividad.instancia.registrarFeature('eliminar_usuario');
        if (mounted) {
          mostrarToast(context, 'Usuario "$nombre" eliminado', tipo: TipoToast.exito);
          _cargar();
        }
      } catch (e) {
        if (mounted) {
          mostrarToast(context, mapearErrorEliminacion(e.toString()), tipo: TipoToast.error);
        }
      }
    }
  }

  // ── TOGGLE ACTIVO ──────────────────────────────────────────
  Future<void> _toggleActivo(String userId, bool actual) async {
    await _client.from('profiles')
        .update({'is_active': !actual}).eq('id', userId);
    _cargar();
  }

  // ── CERRAR SESIÓN ──────────────────────────────────────────
  Future<void> _salir(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ServicioActividad.instancia.cerrarSesion();
      await context.read<ProveedorAuth>().cerrarSesion();
      if (context.mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_outlined, color: kTextSub),
          ),
          IconButton(
            onPressed: () => _salir(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearUsuario,
        backgroundColor: color,
        tooltip: 'Crear usuario',
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: Color(0xFF1C1C1E)),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  hintStyle: const TextStyle(color: kTextSub),
                  prefixIcon: const Icon(Icons.search, color: kTextSub),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Contador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('${_filtrados.length} usuarios',
                    style: const TextStyle(color: kTextSub, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 8),

            // Lista
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _filtrados.isEmpty
                      ? const Center(
                          child: Text('Sin usuarios',
                              style: TextStyle(color: kTextSub)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final u = _filtrados[i];
                            final rol = u['role'] as String? ?? 'client';
                            final activo = u['is_active'] as bool? ?? true;
                            final nombre =
                                u['full_name'] as String? ?? 'Sin nombre';
                            final email = u['email'] as String? ?? '';
                            final miPropiaCuenta = u['id'] ==
                                context.read<ProveedorAuth>().perfil?.id;
                            final esProtegida =
                                rol == 'sysadmin' || miPropiaCuenta;

                            return EntradaAnimada(
                              index: i,
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x08000000), blurRadius: 6)
                                ],
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Text(
                                    nombre.isNotEmpty
                                        ? nombre[0].toUpperCase() : '?',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1C1C1E))),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(email,
                                            style: const TextStyle(
                                                fontSize: 12, color: kTextSub),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                      const SizedBox(height: 2),
                                      _BadgeRol(rol: rol, color: color),
                                    ],
                                  ),
                                ),
                                // Toggle activo/inactivo (bloqueado para
                                // cuentas sysadmin y la propia cuenta)
                                Switch(
                                  value: activo,
                                  activeColor: color,
                                  onChanged: esProtegida
                                      ? null
                                      : (_) =>
                                          _toggleActivo(u['id'], activo),
                                ),
                                // Menú de acciones
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      size: 20, color: color),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  onSelected: (accion) {
                                    if (accion == 'editar') _editarUsuario(u);
                                    if (accion == 'eliminar') _eliminarUsuario(u);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ]),
                                    ),
                                    if (rol != 'sysadmin')
                                      const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ]),
                                      ),
                                  ],
                                ),
                              ]),
                            ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Campo de texto reutilizable ─────────────────────────────
class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String etiqueta;
  final IconData icono;
  final TextInputType tipo;

  const _Campo({
    required this.ctrl,
    required this.etiqueta,
    required this.icono,
    this.tipo = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: kTextSub, size: 20),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Badge de rol ────────────────────────────────────────────
class _BadgeRol extends StatelessWidget {
  final String rol;
  final Color color;
  const _BadgeRol({required this.rol, required this.color});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (rol) {
      'sysadmin'    => ('SYSADMIN', Colors.deepPurple, Colors.white),
      'super_admin' => ('SUPER ADMIN', color.withOpacity(0.15), color),
      'admin'       => ('ADMIN', Colors.orange.withOpacity(0.15), Colors.orange),
      'employee'    => ('EMPLEADO', Colors.blue.withOpacity(0.12), Colors.blue),
      _             => ('CLIENTE', Colors.grey.withOpacity(0.1), Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5)),
    );
  }
}
