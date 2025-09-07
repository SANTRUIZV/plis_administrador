import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  String _selectedFilter = 'pendientes';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Conductores'),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Refrescar la lista
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterChip('Pendientes', 'pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('Verificados', 'verificados'),
                const SizedBox(width: 8),
                _buildFilterChip('Rechazados', 'rechazados'),
              ],
            ),
          ),
          
          // Lista de conductores desde Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getDriversStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar conductores',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final drivers = _filterDrivers(snapshot.data!.docs);

                if (drivers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driverDoc = drivers[index];
                    final driverData = driverDoc.data() as Map<String, dynamic>;
                    return _buildDriverCard(driverDoc.id, driverData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getDriversStream() {
    try {
      return FirebaseFirestore.instance
          .collection('drivers')
          .orderBy('fechaRegistro', descending: true)
          .snapshots();
    } catch (e) {
      // Si hay error con orderBy, intentar sin ordenar
      return FirebaseFirestore.instance
          .collection('drivers')
          .snapshots();
    }
  }

  List<QueryDocumentSnapshot> _filterDrivers(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final estado = data['estado']?.toString() ?? '';
      final verificado = data['verificado'] ?? false;

      switch (_selectedFilter) {
        case 'pendientes':
          return estado == 'pendiente_verificacion' || estado == 'pendiente';
        case 'verificados':
          return verificado == true || estado == 'activo';
        case 'rechazados':
          return estado == 'rechazado';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple.shade600 : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    switch (_selectedFilter) {
      case 'pendientes':
        message = 'No hay conductores pendientes por verificar';
        icon = Icons.check_circle_outline;
        break;
      case 'verificados':
        message = 'No hay conductores verificados aún';
        icon = Icons.verified_outlined;
        break;
      case 'rechazados':
        message = 'No hay conductores rechazados';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No se encontraron conductores';
        icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(String driverId, Map<String, dynamic> driver) {
    final fechaRegistro = _formatDate(driver['fechaRegistro']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    (driver['nombre']?.toString() ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${driver['nombre'] ?? ''} ${driver['apellido'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        driver['email']?.toString() ?? 'Sin email',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(driver['estado'], driver['verificado']),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(driver['telefono']?.toString() ?? 'Sin teléfono'),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(fechaRegistro),
              ],
            ),
            if (driver['documento'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('Documento: ${driver['documento']}'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDriverDetails(driverId, driver),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver Detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (driver['estado'] == 'pendiente_verificacion' || 
                    driver['estado'] == 'pendiente') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading 
                        ? null 
                        : () => _verifyDriver(driverId, driver),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading 
                        ? null 
                        : () => _rejectDriver(driverId, driver),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        // Intenta parsear string
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return timestamp.toString();
      }
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Widget _buildStatusChip(dynamic estado, dynamic verificado) {
    Color color;
    String label;
    IconData icon;

    final estadoStr = estado?.toString() ?? '';
    final isVerified = verificado == true;

    if (isVerified || estadoStr == 'activo') {
      color = Colors.green;
      label = 'Verificado';
      icon = Icons.verified;
    } else if (estadoStr == 'pendiente_verificacion' || estadoStr == 'pendiente') {
      color = Colors.orange;
      label = 'Pendiente';
      icon = Icons.pending;
    } else if (estadoStr == 'rechazado') {
      color = Colors.red;
      label = 'Rechazado';
      icon = Icons.cancel;
    } else {
      color = Colors.grey;
      label = 'Desconocido';
      icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverDetails(String driverId, Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Detalles del Conductor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailItem(
                        icon: Icons.person,
                        title: '${driver['nombre'] ?? ''} ${driver['apellido'] ?? ''}',
                        subtitle: 'Nombre completo',
                      ),
                      _buildDetailItem(
                        icon: Icons.email,
                        title: driver['email']?.toString() ?? 'No disponible',
                        subtitle: 'Correo electrónico',
                      ),
                      _buildDetailItem(
                        icon: Icons.phone,
                        title: driver['telefono']?.toString() ?? 'No disponible',
                        subtitle: 'Teléfono',
                      ),
                      _buildDetailItem(
                        icon: Icons.badge,
                        title: driver['documento']?.toString() ?? 'No disponible',
                        subtitle: 'Número de documento',
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: _formatDate(driver['fechaRegistro']),
                        subtitle: 'Fecha de registro',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Documentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentsSection(driver['documentos']),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentsSection(dynamic documentos) {
    if (documentos == null) {
      return const Text(
        'No hay documentos disponibles',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (documentos is Map) {
      final docs = Map<String, dynamic>.from(documentos);
      if (docs.isEmpty) {
        return const Text(
          'No hay documentos cargados',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (docs['cedula'] != null)
            _buildDocumentItem('Cédula de Identidad', Icons.badge, docs['cedula']),
          if (docs['licencia'] != null)
            _buildDocumentItem('Licencia de Conducir', Icons.drive_eta, docs['licencia']),
          if (docs['tarjeta'] != null)
            _buildDocumentItem('Tarjeta de Propiedad', Icons.description, docs['tarjeta']),
          if (docs['foto'] != null)
            _buildDocumentItem('Foto del Vehículo', Icons.directions_car, docs['foto']),
        ],
      );
    }

    return const Text(
      'Formato de documentos no reconocido',
      style: TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDocumentItem(String title, IconData icon, dynamic url) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade600),
      title: Text(title),
      trailing: url != null
          ? TextButton(
              onPressed: () => _showDocumentDialog(title, url.toString()),
              child: const Text('Ver'),
            )
          : const Text(
              'No disponible',
              style: TextStyle(color: Colors.grey),
            ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDocumentDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('URL del documento:'),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: Copia la URL para abrirla en tu navegador',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyDriver(String driverId, Map<String, dynamic> driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Conductor'),
        content: Text(
          '¿Estás seguro de que quieres aprobar a ${driver['nombre']} ${driver['apellido']}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);

      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .update({
          'estado': 'activo',
          'verificado': true,
          'fechaVerificacion': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conductor aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al aprobar conductor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _rejectDriver(String driverId, Map<String, dynamic> driver) async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Conductor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de que quieres rechazar a ${driver['nombre']} ${driver['apellido']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);

      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .update({
          'estado': 'rechazado',
          'verificado': false,
          'motivoRechazo': reasonController.text.trim(),
          'fechaRechazo': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conductor rechazado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar conductor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }

    reasonController.dispose();
  }
}