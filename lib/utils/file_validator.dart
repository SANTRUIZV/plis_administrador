import 'package:file_picker/file_picker.dart';

class FileValidator {
  // Límites de tamaño en bytes
  static const int MAX_PDF_SIZE = 5 * 1024 * 1024; // 5 MB
  static const int MAX_IMAGE_SIZE = 2 * 1024 * 1024; // 2 MB

  // Límites de tamaño en MB para mostrar al usuario
  static const double MAX_PDF_SIZE_MB = 5.0;
  static const double MAX_IMAGE_SIZE_MB = 2.0;

  /// Valida el tamaño de un archivo según su tipo
  static FileValidationResult validateFileSize(PlatformFile file, String documentType) {
    final fileSize = file.size;
    final fileSizeMB = fileSize / (1024 * 1024);

    if (documentType == 'foto') {
      // Validar imagen
      if (fileSize > MAX_IMAGE_SIZE) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'La imagen es muy grande. Tamaño máximo: ${MAX_IMAGE_SIZE_MB}MB. '
              'Tu archivo: ${fileSizeMB.toStringAsFixed(1)}MB',
          currentSizeMB: fileSizeMB,
          maxSizeMB: MAX_IMAGE_SIZE_MB,
        );
      }
    } else {
      // Validar PDF (licencia o tarjeta)
      if (fileSize > MAX_PDF_SIZE) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'El PDF es muy grande. Tamaño máximo: ${MAX_PDF_SIZE_MB}MB. '
              'Tu archivo: ${fileSizeMB.toStringAsFixed(1)}MB',
          currentSizeMB: fileSizeMB,
          maxSizeMB: MAX_PDF_SIZE_MB,
        );
      }
    }

    return FileValidationResult(
      isValid: true,
      currentSizeMB: fileSizeMB,
      maxSizeMB: documentType == 'foto' ? MAX_IMAGE_SIZE_MB : MAX_PDF_SIZE_MB,
    );
  }

  /// Formatea el tamaño de archivo a texto legible
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Obtiene sugerencias para reducir el tamaño del archivo
  static List<String> getCompressionSuggestions(String documentType) {
    if (documentType == 'foto') {
      return [
        '• Toma la foto con menor resolución',
        '• Usa una app de compresión de imágenes',
        '• Guarda como JPEG en lugar de PNG',
        '• Ajusta la calidad de la imagen al 80-90%'
      ];
    } else {
      return [
        '• Escanea en menor resolución (150-300 DPI)',
        '• Usa compresión al crear el PDF',
        '• Asegúrate de que sea texto, no imagen escaneada',
        '• Usa herramientas online de compresión PDF'
      ];
    }
  }
}

/// Resultado de la validación de archivos
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double currentSizeMB;
  final double maxSizeMB;

  FileValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.currentSizeMB,
    required this.maxSizeMB,
  });

  /// Porcentaje del límite usado (0.0 - 1.0)
  double get usagePercentage => currentSizeMB / maxSizeMB;

  /// Color sugerido según el porcentaje de uso
  String get statusColor {
    if (usagePercentage < 0.5) return 'green'; // < 50%
    if (usagePercentage < 0.8) return 'orange'; // 50-80%
    return 'red'; // > 80%
  }
}