import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si no hay usuario autenticado
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // Si hay usuario autenticado, verificar su rol
        return FutureBuilder<bool>(
          future: _checkUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (roleSnapshot.hasError || roleSnapshot.data != true) {
              // Si hay error o no es superadmin, cerrar sesión y mostrar login
              FirebaseAuth.instance.signOut();
              return _buildAccessDeniedScreen();
            }

            // Si es superadmin, mostrar home
            return const HomeScreen();
          },
        );
      },
    );
  }

  // Función helper para parsear datos de Firestore de manera segura
  Map<String, dynamic>? _parseFirestoreData(Object? data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('Error parseando datos de Firestore: $e');
    }

    return null;
  }

  Future<bool> _checkUserRole(String userId) async {
    try {
      // Verificar en la colección 'admins' en lugar de 'users'
      final DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();

      if (!adminDoc.exists) {
        return false;
      }

      // Parse más seguro para evitar errores
      final Map<String, dynamic>? adminData = _parseFirestoreData(
        adminDoc.data(),
      );

      if (adminData == null) {
        return false;
      }

      final String userRole = adminData['role']?.toString() ?? '';
      final String estado = adminData['estado']?.toString() ?? '';

      // Permitir cualquier rol activo
      return estado == 'activo' &&
          [
            'superadmin',
            'admin',
            'moderador',
            'finanzas',
            'soporte',
          ].contains(userRole);
    } catch (e) {
      print('Error verificando rol: $e');
      return false;
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade300,
              Colors.deepPurple.shade600,
              Colors.indigo.shade700,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 24),
              Text(
                'Verificando permisos...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade300,
              Colors.red.shade600,
              Colors.red.shade800,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.block,
                        size: 40,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Acceso Denegado',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Solo los administradores con permisos especiales pueden acceder a esta aplicación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Volver al Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
    );
  }
}
