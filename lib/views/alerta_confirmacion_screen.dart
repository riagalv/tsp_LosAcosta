import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertaConfirmacionScreen extends StatefulWidget {
  final String nivelRiesgo;

  const AlertaConfirmacionScreen({super.key, required this.nivelRiesgo});

  @override
  State<AlertaConfirmacionScreen> createState() =>
      _AlertaConfirmacionScreenState();
}

class _AlertaConfirmacionScreenState extends State<AlertaConfirmacionScreen>
    with SingleTickerProviderStateMixin {
  Position? _posicion;
  String _ubicacionTexto = 'Obteniendo ubicación...';
  bool _cargando = true;

  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkController.forward();

    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _ubicacionTexto = 'Servicios de ubicación deshabilitados';
          _cargando = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _ubicacionTexto = 'Permiso de ubicación denegado';
            _cargando = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _ubicacionTexto = 'Permiso de ubicación denegado permanentemente';
          _cargando = false;
        });
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _posicion = posicion;
          _ubicacionTexto =
              '${posicion.latitude.toStringAsFixed(4)}, ${posicion.longitude.toStringAsFixed(4)}';
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ubicacionTexto = 'Error al obtener ubicación';
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Título ALERTACAN
              const Text(
                'A L E R T A C A N',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE84C3D),
                  letterSpacing: 4,
                ),
              ),

              const Spacer(flex: 1),

              // Check animado
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 36,
                    color: Color(0xFFE8913D),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Alerta enviada
              const Text(
                'Alerta\nenviada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C2833),
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 16),

              // Texto informativo
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(text: 'Notificamos a vecinos en un radio de '),
                    TextSpan(
                      text: '500m',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    TextSpan(text: '\nsobre un reporte de riesgo.'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Mapa real con Google Maps
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cargando
                      ? Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _posicion != null
                          ? Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      _posicion!.latitude,
                                      _posicion!.longitude,
                                    ),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('ubicacion'),
                                      position: LatLng(
                                        _posicion!.latitude,
                                        _posicion!.longitude,
                                      ),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueRed,
                                      ),
                                    ),
                                  },
                                  circles: {
                                    Circle(
                                      circleId: const CircleId('radio'),
                                      center: LatLng(
                                        _posicion!.latitude,
                                        _posicion!.longitude,
                                      ),
                                      radius: 500,
                                      fillColor: const Color(0x15E84C3D),
                                      strokeColor: const Color(0x40E84C3D),
                                      strokeWidth: 1,
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  myLocationEnabled: false,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                                // Label de ubicación
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _ubicacionTexto,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C2C2C),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_off,
                                        size: 32, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      _ubicacionTexto,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 16),

              // Personas alertadas
              const Text(
                'X PERSONAS ALERTADAS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE84C3D),
                  letterSpacing: 1,
                ),
              ),

              const Spacer(flex: 2),

              // Botón volver
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C2833),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'VOLVER AL INICIO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
