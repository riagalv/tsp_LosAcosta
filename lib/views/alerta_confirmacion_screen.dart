import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/alerta_confirmacion_controller.dart';
import 'mapa_expandido_screen.dart';

class AlertaConfirmacionView extends StatefulWidget {
  final String nivelRiesgo;

  const AlertaConfirmacionView({super.key, required this.nivelRiesgo});

  @override
  State<AlertaConfirmacionView> createState() => _AlertaConfirmacionViewState();
}

class _AlertaConfirmacionViewState extends State<AlertaConfirmacionView>
    with SingleTickerProviderStateMixin {
  late AlertaConfirmacionController _controller;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    // Pasa el nivelRiesgo al controlador
    _controller = AlertaConfirmacionController(nivelRiesgo: widget.nivelRiesgo);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkController.forward();

    _controller.onUbicacionActualizada = () {
      if (mounted) setState(() {});
    };
    _controller.onError = () {
      if (mounted) setState(() {});
    };

    _controller.obtenerUbicacion();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
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

              // Animación check
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
              _buildMapaWidget(),

              const SizedBox(height: 16),
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
              _buildBotonVolver(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapaWidget() {
    return GestureDetector(
      onTap: () {
        if (_controller.posicion != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapaExpandidoScreen(
                latitud: _controller.posicion!.latitude,
                longitud: _controller.posicion!.longitude,
              ),
            ),
          );
        }
      },
      child: Container(
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
          child: _controller.cargando
              ? Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.posicion != null
              ? Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _controller.posicion!.latitude,
                          _controller.posicion!.longitude,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('ubicacion'),
                          position: LatLng(
                            _controller.posicion!.latitude,
                            _controller.posicion!.longitude,
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
                            _controller.posicion!.latitude,
                            _controller.posicion!.longitude,
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
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          _controller.ubicacionTexto ?? '',
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
                        Icon(
                          Icons.location_off,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.ubicacionTexto ?? '',
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
    );
  }

  Widget _buildBotonVolver() {
    return SizedBox(
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
    );
  }
}
