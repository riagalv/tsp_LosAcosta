import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio de subida de imágenes a Cloudinary.
/// Requiere configurar las constantes con los datos de tu cuenta.
class CloudinaryService {
  // ── CONFIGURA AQUÍ TUS CREDENCIALES DE CLOUDINARY ──────────────────────
  static const String _cloudName = 'dnbdnswql';
  static const String _uploadPreset = 'alertacan_preset';
  // ────────────────────────────────────────────────────────────────────────

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Sube [archivo] a Cloudinary y devuelve la URL pública de la imagen.
  /// Lanza una excepción si la subida falla.
  static Future<String> subirImagen(File archivo) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', archivo.path),
      );

      final response = await request.send();
      final respBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(respBody);
        return json['secure_url'] as String;
      } else {
        debugPrint('Cloudinary error: $respBody');
        throw Exception('Error al subir imagen (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('CloudinaryService.subirImagen: $e');
      rethrow;
    }
  }
}
