import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/alerta_model.dart';

class PdfController {
  static String? _tempPath;

  Future<File> generarPdfIncidente(AlertaModel alerta) async {
    try {
      final pdf = pw.Document();

      // Formatear datos
      final idSeguro = alerta.id ?? 'SINID';
      final String fechaStr = alerta.fecha != null 
          ? '${alerta.fecha!.day}/${alerta.fecha!.month}/${alerta.fecha!.year} ${alerta.fecha!.hour.toString().padLeft(2, '0')}:${alerta.fecha!.minute.toString().padLeft(2, '0')} hrs'
          : 'Fecha no disponible';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('REPORTE DE ALERTA OFICIAL', 
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                        pw.Text('ALERTACAN', 
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Información principal
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildFilaDetalle('ID de Reporte:', idSeguro.toUpperCase()),
                        pw.SizedBox(height: 8),
                        _buildFilaDetalle('Fecha y Hora:', fechaStr),
                        pw.SizedBox(height: 8),
                        _buildFilaDetalle('Nivel de Riesgo:', alerta.riesgo.toUpperCase(), 
                          color: _getPdfColorPorRiesgo(alerta.riesgo)),
                        pw.SizedBox(height: 8),
                        _buildFilaDetalle('Estado:', alerta.estado.toUpperCase()),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 24),
                  pw.Text('Detalles de Ubicación', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _buildFilaDetalle('Dirección aproximada:', alerta.direccion),
                  pw.SizedBox(height: 8),
                  _buildFilaDetalle('Coordenadas:', '${alerta.latitud.toStringAsFixed(6)}, ${alerta.longitud.toStringAsFixed(6)}'),
                  
                  pw.SizedBox(height: 24),
                  pw.Text('Información de Emisión', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _buildFilaDetalle('Emisor:', alerta.emisor),
                  pw.SizedBox(height: 8),
                  _buildFilaDetalle('Personas Alertadas:', '${alerta.personasAlertadas} vecinos notificados'),
                  
                  pw.Spacer(),
                  
                  // Pie de página
                  pw.Divider(),
                  pw.Center(
                    child: pw.Text(
                      'Este documento es generado automáticamente por el sistema AlertaCan y sirve como registro oficial de la alerta emitida.',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();

      _tempPath ??= (await getTemporaryDirectory()).path;
      final file = File('$_tempPath/${obtenerNombreArchivo(alerta)}');
      
      await file.writeAsBytes(bytes, flush: false);
      return file;

    } catch (e) {
      throw Exception('No se pudo generar el PDF localmente: $e');
    }
  }

  pw.Widget _buildFilaDetalle(String titulo, String valor, {PdfColor? color}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 140,
          child: pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
        ),
        pw.Expanded(
          child: pw.Text(valor, style: pw.TextStyle(fontWeight: color != null ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ),
      ],
    );
  }

  PdfColor _getPdfColorPorRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return PdfColors.red700;
      case 'MEDIO':
        return PdfColors.orange700;
      case 'BAJO':
        return PdfColors.yellow700;
      default:
        return PdfColors.orange700;
    }
  }

  String obtenerNombreArchivo(AlertaModel alerta) {
    final idSeguro = alerta.id ?? 'SINID';
    return 'REPORTE_${idSeguro.substring(0, idSeguro.length >= 5 ? 5 : idSeguro.length)}.pdf';
  }
}
