import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alerta_model.dart';
import '../services/ubicacion_service.dart';

class MapaController {
  final FirebaseFirestore _firestore;
  final UbicacionService _ubicacionService;

  MapaController({
    FirebaseFirestore? firestore,
    UbicacionService? ubicacionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ubicacionService = ubicacionService ?? UbicacionService();

  GoogleMapController? mapController;
  Position? miPosicion;
  bool gpsActivo = false;
  Set<Marker> markers = {};

  // Callbacks para actualizar la vista
  Function? onMapaActualizado;
  Function(String)? onError;
  Function(AlertaModel)? onMostrarDetalle;

  // Obtener ubicación actual
  Future<void> obtenerUbicacionActual() async {
    try {
      final posicion = await _ubicacionService.obtenerUbicacionActual();
      miPosicion = posicion;
      gpsActivo = true;

      if (onMapaActualizado != null) onMapaActualizado!();
    } catch (e) {
      if (onError != null) onError!('Error al obtener ubicación: $e');
    }
  }

  // Cargar alertas en tiempo real
  void cargarAlertas() {
    _firestore.collection('alertas').snapshots().listen((snapshot) async {
      final nuevosMarkers = <Marker>{};

      for (final doc in snapshot.docs) {
        // Cambia de Alerta.fromFirestore a AlertaModel.fromFirestore
        final alerta = AlertaModel.fromFirestore(doc); // ✅ Ahora funciona
        //final alerta = AlertaModel.fromFirestore(doc);

        if (alerta.latitud == 0.0 && alerta.longitud == 0.0) continue;

        final icono = await _crearIconoPersonalizado(alerta.riesgo);

        nuevosMarkers.add(
          Marker(
            markerId: MarkerId(alerta.id!),
            position: LatLng(alerta.latitud, alerta.longitud),
            icon: icono,
            onTap: () {
              if (onMostrarDetalle != null) onMostrarDetalle!(alerta);
            },
          ),
        );
      }

      markers = nuevosMarkers;
      if (onMapaActualizado != null) onMapaActualizado!();
    });
  }

  // Crear icono personalizado
  Future<BitmapDescriptor> _crearIconoPersonalizado(String riesgo) async {
    final color = _colorParaRiesgo(riesgo);
    final size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 2),
      size / 2 - 6,
      shadowPaint,
    );

    // Borde blanco
    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Círculo de color
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, circlePaint);

    // Triángulo de advertencia
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size / 2;
    final cy = size / 2;
    path.moveTo(cx, cy - 22);
    path.lineTo(cx + 20, cy + 14);
    path.lineTo(cx - 20, cy + 14);
    path.close();
    canvas.drawPath(path, iconPaint);

    // Signo de exclamación
    final exclamationPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 5, height: 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, exclamationPaint);
    canvas.drawCircle(Offset(cx, cy + 10), 3, exclamationPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes, width: 44, height: 44);
  }

  // Obtener color según riesgo
  Color _colorParaRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return const Color(0xFFE84C3D);
      case 'MEDIO':
        return const Color(0xFFF48C42);
      case 'BAJO':
        return const Color(0xFFF4C542);
      default:
        return const Color(0xFFF48C42);
    }
  }

  // Métodos públicos para la vista
  Color getColorPorRiesgo(String riesgo) => _colorParaRiesgo(riesgo);

  String getEtiquetaRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return 'Rojo - Alto';
      case 'MEDIO':
        return 'Naranja - Medio';
      case 'BAJO':
        return 'Amarillo - Bajo';
      default:
        return riesgo;
    }
  }

  String getTiempoTranscurrido(Timestamp fecha) {
    final diff = DateTime.now().difference(fecha.toDate());
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds} seg';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  void centrarEnMiUbicacion() {
    if (miPosicion != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(miPosicion!.latitude, miPosicion!.longitude),
          15.5,
        ),
      );
    }
  }

  void moverCamara(double latitud, double longitud, double zoom) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitud, longitud), zoom),
      );
    }
  }

  void dispose() {
    mapController = null;
  }
}
