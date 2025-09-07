import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_verification_screen.dart';
import 'admin_register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  
  // Contadores dinámicos
  int _pendingCount = 0;
  int _verifiedCount = 0;
  int _rejectedCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final QuerySnapshot driversSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .get();

      int pending = 0;
      int verified = 0;
      int rejected = 0;

      for (var doc in driversSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final estado = data['estado']?.toString() ?? '';
        final verificado = data['verificado'] ?? false;

        if (estado == 'pendiente_verificacion' || estado == 'pendiente') {
          pending++;
        } else if (verificado == true || estado == 'activo') {
          verified++;
        } else if (estado == 'rechazado') {
          rejected++;
        }
      }

      if (mounted) {
        setState(() {
          _pendingCount = pending;
          _verifiedCount = verified;
          _rejectedCount = rejected;
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('Error cargando estadísticas: $e');
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade600,
                        Colors.indigo.shade700,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plis Administradores',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Bienvenido, ${user?.displayName ?? 'Administrador'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Barra de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar conductores, usuarios...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: Colors.deepPurple.shade600,
                              ),
                              onPressed: () {
                                // Implementar filtros
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (value) {
                            print('Buscar: $value');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido principal
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Estadísticas rápidas
                          _buildQuickStats(),
                          const SizedBox(height: 30),
                          
                          // Acciones principales
                          const Text(
                            'Gestión Principal',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildMainActions(),
                          const SizedBox(height: 30),
                          
                          // Administración del sistema
                          const Text(
                            'Administración del Sistema',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildAdminTools(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Pendientes',
            value: _loadingStats ? '...' : _pendingCount.toString(),
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Verificados',
            value: _loadingStats ? '...' : _verifiedCount.toString(),
            icon: Icons.verified,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Rechazados',
            value: _loadingStats ? '...' : _rejectedCount.toString(),
            icon: Icons.cancel,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          title: 'Verificar Conductores',
          subtitle: 'Revisar documentos',
          icon: Icons.assignment_turned_in,
          gradient: [Colors.blue.shade400, Colors.blue.shade600],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverVerificationScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: 'Gestionar Usuarios',
          subtitle: 'Ver todos los usuarios',
          icon: Icons.people,
          gradient: [Colors.green.shade400, Colors.green.shade600],
          onTap: () {
            // Navigator.push(...);
          },
        ),
        _buildActionCard(
          title: 'Estadísticas',
          subtitle: 'Métricas del sistema',
          icon: Icons.analytics,
          gradient: [Colors.purple.shade400, Colors.purple.shade600],
          onTap: () {
            // Navigator.push(...);
          },
        ),
        _buildActionCard(
          title: 'Reportes',
          subtitle: 'Incidentes y quejas',
          icon: Icons.report_problem,
          gradient: [Colors.orange.shade400, Colors.orange.shade600],
          onTap: () {
            // Navigator.push(...);
          },
        ),
      ],
    );
  }

  Widget _buildAdminTools() {
    return Column(
      children: [
        _buildToolButton(
          title: 'Crear Administrador',
          subtitle: 'Agregar nuevo administrador al sistema',
          icon: Icons.person_add,
          color: Colors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminRegisterScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildToolButton(
          title: 'Configuración de Tarifas',
          subtitle: 'Ajustar precios y comisiones',
          icon: Icons.monetization_on,
          color: Colors.green,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildToolButton(
          title: 'Zonas de Servicio',
          subtitle: 'Gestionar áreas de cobertura',
          icon: Icons.map,
          color: Colors.blue,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildToolButton(
          title: 'Notificaciones',
          subtitle: 'Enviar avisos masivos',
          icon: Icons.notifications,
          color: Colors.orange,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildToolButton(
          title: 'Respaldos',
          subtitle: 'Exportar datos del sistema',
          icon: Icons.backup,
          color: Colors.teal,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}