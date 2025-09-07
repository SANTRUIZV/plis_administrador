class UserData {
  final String nombre;
  final String apellido;
  final String email;
  final String documento;
  final String telefono;
  final String password; // Mantenerlo para compatibilidad pero no se usará
  final String estado; // 'pendiente_verificacion', 'activo', 'rechazado'
  final bool verificado;

  UserData({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.documento,
    required this.telefono,
    required this.password,
    this.estado = 'pendiente_verificacion',
    this.verificado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'documento': documento,
      'telefono': telefono,
      'estado': estado,
      'verificado': verificado,
      // NO incluir password en el mapa
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      documento: map['documento'] ?? '',
      telefono: map['telefono'] ?? '',
      password: '', // Ya no se obtiene de Firestore
      estado: map['estado'] ?? 'pendiente_verificacion',
      verificado: map['verificado'] ?? false,
    );
  }

  // Método para verificar si el usuario puede acceder a la app
  bool get canAccessApp => verificado && estado == 'activo';

  // Método para obtener el estado como texto legible
  String get estadoTexto {
    switch (estado) {
      case 'activo':
        return 'Verificado';
      case 'rechazado':
        return 'Rechazado';
      case 'pendiente_verificacion':
      default:
        return 'Pendiente de verificación';
    }
  }
}