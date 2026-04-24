import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alerta_model.dart';

class PdfController {
  static String? _tempPath;

  /// Delegamos la generación del PDF usando el SDK nativo de Firebase Functions.
  /// Esto es más seguro, no requiere quemar URLs en el código y maneja la red por ti.
  Future<File> generarPdfIncidente(AlertaModel alerta) async {
    final idSeguro = alerta.id ?? 'SINID';
    
    try {
      // 1. Llamamos a la función de Firebase por su nombre exacto
      final callable = FirebaseFunctions.instance.httpsCallable('generarPdfAlerta');
      final result = await callable.call({'id': idSeguro});

      // 2. La función nos devuelve el PDF empaquetado en formato Base64. 
      // Lo decodificamos a bytes binarios reales.
      final String base64Pdf = result.data['pdfBase64'];
      final bytes = base64Decode(base64Pdf);

      // 3. Guardamos los bytes en un archivo PDF temporal
      _tempPath ??= (await getTemporaryDirectory()).path;
      final file = File('$_tempPath/${obtenerNombreArchivo(alerta)}');
      
      await file.writeAsBytes(bytes, flush: false);
      return file;

    } on FirebaseFunctionsException catch (e) {
      throw Exception('Error de servidor Firebase: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo generar el PDF. Verifica tu conexión.');
    }
  }

  String obtenerNombreArchivo(AlertaModel alerta) {
    final idSeguro = alerta.id ?? 'SINID';
    return 'REPORTE_${idSeguro.substring(0, idSeguro.length >= 5 ? 5 : idSeguro.length)}.pdf';
  }
}
