import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alerta_model.dart';

class MapaExpandidoScreen extends StatefulWidget {
  final double? latitud;
  final double? longitud;

  const MapaExpandidoScreen({super.key, this.latitud, this.longitud});

  @override
  State<MapaExpandidoScreen> createState() => _MapaExpandidoScreenState();
}

class _MapaExpandidoScreenState extends State<MapaExpandidoScreen> {
  GoogleMapController? _mapController;
  Position? _miPosicion;
  bool _gpsActivo = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _cargarAlertas();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _miPosicion = posicion;
          _gpsActivo = true;
        });
      }
    } catch (_) {}
  }

  void _cargarAlertas() {
    FirebaseFirestore.instance
        .collection('alertas')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      final alertas =
          snapshot.docs.map((doc) => Alerta.fromFirestore(doc)).toList();

      final Set<Marker> nuevosMarkers = {};

      for (final alerta in alertas) {
        if (alerta.latitud == 0.0 && alerta.longitud == 0.0) continue;

        final icono = await _crearIconoPersonalizado(alerta.riesgo);

        nuevosMarkers.add(Marker(
          markerId: MarkerId(alerta.id),
          position: LatLng(alerta.latitud, alerta.longitud),
          icon: icono,
          onTap: () => _mostrarDetalleIncidente(alerta),
        ));
      }

      if (mounted) {
        setState(() => _markers = nuevosMarkers);
      }
    });
  }

  Future<BitmapDescriptor> _crearIconoPersonalizado(String riesgo) async {
    final color = _colorParaRiesgo(riesgo);
    final size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size / 2, size / 2 + 2), size / 2 - 6, shadowPaint);

    // Borde blanco
    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Círculo de color
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, circlePaint);

    // Icono de advertencia (triángulo con !)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Triángulo
    final path = Path();
    final cx = size / 2;
    final cy = size / 2;
    path.moveTo(cx, cy - 22);
    path.lineTo(cx + 20, cy + 14);
    path.lineTo(cx - 20, cy + 14);
    path.close();
    canvas.drawPath(path, iconPaint);

    // Signo de exclamación dentro del triángulo
    final exclamationPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Línea del !
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 5, height: 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, exclamationPaint);

    // Punto del !
    canvas.drawCircle(Offset(cx, cy + 10), 3, exclamationPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes, width: 44, height: 44);
  }


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

  String _etiquetaRiesgo(String riesgo) {
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

  String _tiempoTranscurrido(Timestamp fecha) {
    final diff = DateTime.now().difference(fecha.toDate());
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds} seg';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  void _centrarEnMiUbicacion() {
    if (_miPosicion != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_miPosicion!.latitude, _miPosicion!.longitude),
          15.5,
        ),
      );
    }
  }

  void _mostrarDetalleIncidente(Alerta alerta) {
    final color = _colorParaRiesgo(alerta.riesgo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Título
                      const Text(
                        'Detalles del Incidente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C2833),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Ubicación
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alerta.direccion.isNotEmpty
                                  ? alerta.direccion
                                  : '${alerta.latitud.toStringAsFixed(4)}, ${alerta.longitud.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Card nivel de riesgo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                color: color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NIVEL DE RIESGO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _etiquetaRiesgo(alerta.riesgo),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Hora y Emisor
                      Row(
                        children: [
                          // Hora
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 22, color: Colors.orange.shade300),
                                  const SizedBox(height: 6),
                                  Text(
                                    'HORA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tiempoTranscurrido(alerta.fecha),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Emisor
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.person,
                                      size: 22, color: Colors.brown.shade300),
                                  const SizedBox(height: 6),
                                  Text(
                                    'EMISOR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alerta.emisor,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Alcance
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // Avatares placeholder
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: Stack(
                                children: [
                                  _buildAvatar(0, Icons.person),
                                  Positioned(
                                    left: 18,
                                    child: _buildAvatar(0, Icons.person),
                                  ),
                                  Positioned(
                                    left: 36,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade300,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALCANCE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade400,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Text(
                                    'X Vecinos Notificados',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.groups,
                                size: 28, color: Colors.grey.shade400),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón ver en mapa completo
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(alerta.latitud, alerta.longitud),
                                17,
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text(
                            'VER EN MAPA COMPLETO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF48C42),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(int index, IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.brown.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centroInicial = widget.latitud != null && widget.longitud != null
        ? LatLng(widget.latitud!, widget.longitud!)
        : const LatLng(22.7415, -102.3716); // Trancoso default

    return Scaffold(
      body: Stack(
        children: [
          // Mapa a pantalla completa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centroInicial,
              zoom: 14.5,
            ),
            markers: _markers,
            myLocationEnabled: _gpsActivo,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Barra superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Botón de regreso
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF2C2C2C), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MAPA DE ALERTAS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2833),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),

                  // GPS Activo indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gpsActivo
                                ? const Color(0xFFF4C542)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _gpsActivo ? 'GPS ACTIVO' : 'GPS INACTIVO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leyenda de colores
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeyendaItem(const Color(0xFFE84C3D), 'ALTO RIESGO'),
                  const SizedBox(height: 6),
                  _buildLeyendaItem(
                      const Color(0xFFF48C42), 'MEDIO RIESGO'),
                  const SizedBox(height: 6),
                  _buildLeyendaItem(const Color(0xFFF4C542), 'BAJO RIESGO'),
                ],
              ),
            ),
          ),

          // Barra de búsqueda inferior + botón centrar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Row(
              children: [
                // Barra de búsqueda
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade400),
                        const SizedBox(width: 10),
                        Text(
                          'Buscar zona o calle...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón centrar en mi ubicación
                GestureDetector(
                  onTap: _centrarEnMiUbicacion,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.red.shade400,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}
