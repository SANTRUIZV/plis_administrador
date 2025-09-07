import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String _selectedRole = 'admin'; // Valor por defecto

  // Definición de roles disponibles
  final Map<String, Map<String, dynamic>> _availableRoles = {
    'superadmin': {
      'name': 'Super Administrador',
      'description': 'Acceso completo al sistema',
      'icon': Icons.admin_panel_settings,
      'color': Colors.red,
      'permissions': {
        'crearAdmins': true,
        'editarAdmins': true,
        'eliminarAdmins': true,
        'verReportes': true,
        'configurarSistema': true,
        'gestionarUsuarios': true,
        'moderarContenido': true,
        'verEstadisticas': true,
        'gestionarFinanzas': true,
      },
    },
    'admin': {
      'name': 'Administrador',
      'description': 'Gestión general del sistema',
      'icon': Icons.shield,
      'color': Colors.blue,
      'permissions': {
        'crearAdmins': false,
        'editarAdmins': true,
        'eliminarAdmins': false,
        'verReportes': true,
        'configurarSistema': false,
        'gestionarUsuarios': true,
        'moderarContenido': true,
        'verEstadisticas': true,
        'gestionarFinanzas': false,
      },
    },
    'moderador': {
      'name': 'Moderador',
      'description': 'Moderación de contenido y usuarios',
      'icon': Icons.security,
      'color': Colors.green,
      'permissions': {
        'crearAdmins': false,
        'editarAdmins': false,
        'eliminarAdmins': false,
        'verReportes': true,
        'configurarSistema': false,
        'gestionarUsuarios': true,
        'moderarContenido': true,
        'verEstadisticas': false,
        'gestionarFinanzas': false,
      },
    },
    'finanzas': {
      'name': 'Gestor Financiero',
      'description': 'Gestión de finanzas y reportes económicos',
      'icon': Icons.account_balance,
      'color': Colors.purple,
      'permissions': {
        'crearAdmins': false,
        'editarAdmins': false,
        'eliminarAdmins': false,
        'verReportes': true,
        'configurarSistema': false,
        'gestionarUsuarios': false,
        'moderarContenido': false,
        'verEstadisticas': true,
        'gestionarFinanzas': true,
      },
    },
    'soporte': {
      'name': 'Soporte Técnico',
      'description': 'Atención al cliente y soporte técnico',
      'icon': Icons.support_agent,
      'color': Colors.orange,
      'permissions': {
        'crearAdmins': false,
        'editarAdmins': false,
        'eliminarAdmins': false,
        'verReportes': false,
        'configurarSistema': false,
        'gestionarUsuarios': true,
        'moderarContenido': false,
        'verEstadisticas': false,
        'gestionarFinanzas': false,
      },
    },
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerAdmin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🔄 Iniciando registro de administrador...');

      // Verificar permisos del usuario actual
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'Debes estar autenticado para crear administradores';
      }

      // Verificar que el usuario actual tenga permisos para crear admins
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        throw 'No tienes permisos para realizar esta acción';
      }

      final currentUserData = currentUserDoc.data()!;
      final currentUserPermissions =
          currentUserData['permisos'] as Map<String, dynamic>? ?? {};

      if (!currentUserPermissions['crearAdmins']) {
        throw 'No tienes permisos para crear administradores';
      }

      // Crear usuario en Firebase Auth
      print('🔄 Creando usuario en Firebase Auth...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final String userId = userCredential.user!.uid;
      print('✅ Usuario creado exitosamente. UID: $userId');

      // Crear el documento en la colección 'admins'
      print('🔄 Creando documento en Firestore...');
      await _createAdminDocument(userId, currentUser.uid);

      // Actualizar displayName
      await userCredential.user!.updateDisplayName(_nameController.text.trim());
      print('✅ DisplayName actualizado');

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡${_availableRoles[_selectedRole]!['name']} registrado exitosamente!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Volver a la pantalla anterior después de 1 segundo
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true); // Retorna true para indicar éxito
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      setState(() {
        _error = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      print('❌ Error general: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createAdminDocument(String userId, String createdBy) async {
    try {
      print('📝 Preparando datos para guardar en Firestore...');

      final roleData = _availableRoles[_selectedRole]!;
      final adminData = {
        'nombre': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'role': _selectedRole,
        'estado': 'activo',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'ultimoAcceso': null,
        'creadoPor': createdBy,
        'permisos': roleData['permissions'],
        'descripcionRole': roleData['description'],
      };

      print('🔄 Datos a guardar: $adminData');

      // Crear el documento en Firestore
      print('🔄 Guardando en collection admins...');
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .set(adminData);

      print('✅ Documento guardado en Firestore exitosamente');

      // Verificar que se guardó correctamente
      print('🔍 Verificando que el documento existe...');
      final docSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        print('✅ ÉXITO: Documento verificado en Firestore');
        print('📋 Datos guardados: ${docSnapshot.data()}');
      } else {
        print('❌ ERROR: Documento no encontrado después de crearlo');
        throw 'El documento no se guardó correctamente en Firestore';
      }
    } catch (e) {
      print('❌ Error al crear documento: $e');

      // Intentar eliminar el usuario de Auth si falló Firestore
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        print('🧹 Usuario eliminado de Auth debido a fallo en Firestore');
      } catch (deleteError) {
        print('⚠️ No se pudo eliminar usuario de Auth: $deleteError');
      }

      if (e.toString().contains('permission-denied')) {
        throw 'Error de permisos: Verifica las reglas de Firestore en la consola de Firebase';
      } else if (e.toString().contains('network')) {
        throw 'Error de conexión: Verifica tu conexión a internet';
      } else {
        throw 'Error al guardar en base de datos: $e';
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al administrador';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión a internet';
      default:
        return 'Error de registro: $errorCode';
    }
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Administrador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
              style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
              selectedItemBuilder: (BuildContext context) {
                return _availableRoles.entries.map((entry) {
                  final roleData = entry.value;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Menos padding
                        decoration: BoxDecoration(
                          color: (roleData['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          roleData['icon'] as IconData,
                          color: roleData['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        roleData['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: _availableRoles.entries.map((entry) {
                final roleKey = entry.key;
                final roleData = entry.value;

                return DropdownMenuItem<String>(
                  value: roleKey,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                    ), // <-- Cambia 8 por 4 o 0
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (roleData['color'] as Color).withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            roleData['icon'] as IconData,
                            color: roleData['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                roleData['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                roleData['description'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsPreview() {
    final roleData = _availableRoles[_selectedRole]!;
    final permissions = roleData['permissions'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (roleData['color'] as Color).withOpacity(0.05),
        border: Border.all(
          color: (roleData['color'] as Color).withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: roleData['color'] as Color, size: 16),
              const SizedBox(width: 8),
              Text(
                'Permisos del ${roleData['name']}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: roleData['color'] as Color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: permissions.entries.map((permission) {
              final hasPermission = permission.value as bool;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPermission
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPermission ? Icons.check : Icons.close,
                      size: 12,
                      color: hasPermission
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPermissionDisplayName(permission.key),
                      style: TextStyle(
                        fontSize: 10,
                        color: hasPermission
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getPermissionDisplayName(String permissionKey) {
    final displayNames = {
      'crearAdmins': 'Crear Admins',
      'editarAdmins': 'Editar Admins',
      'eliminarAdmins': 'Eliminar Admins',
      'verReportes': 'Ver Reportes',
      'configurarSistema': 'Configurar Sistema',
      'gestionarUsuarios': 'Gestionar Usuarios',
      'moderarContenido': 'Moderar Contenido',
      'verEstadisticas': 'Ver Estadísticas',
      'gestionarFinanzas': 'Gestionar Finanzas',
    };
    return displayNames[permissionKey] ?? permissionKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Administrador'),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade300,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade400,
                                  Colors.indigo.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Título
                          Text(
                            'Nuevo Administrador',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea una nueva cuenta de administrador con permisos específicos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Selector de roles (DROPDOWN)
                          _buildRoleSelector(),
                          const SizedBox(height: 20),

                          // Vista previa de permisos
                          _buildPermissionsPreview(),
                          const SizedBox(height: 24),

                          // Campo nombre
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.deepPurple.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el nombre completo';
                              }
                              if (value.length < 2) {
                                return 'El nombre debe tener al menos 2 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Campo email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.deepPurple.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un correo electrónico';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Ingrese un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Campo contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: Colors.deepPurple.shade400,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese una contraseña';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Confirmar contraseña
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: Colors.deepPurple.shade400,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirme su contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Error message
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Botón registro
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _registerAdmin();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 8,
                                shadowColor: Colors.deepPurple.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade400,
                                      Colors.indigo.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Crear ${_availableRoles[_selectedRole]!['name']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
