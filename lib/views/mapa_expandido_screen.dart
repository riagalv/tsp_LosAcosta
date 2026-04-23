import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/mapa_controller.dart';
import '../models/alerta_model.dart';
import '../widgets/detalle_incidente_widget.dart';

class MapaExpandidoScreen extends StatefulWidget {
  final double? latitud;
  final double? longitud;

  const MapaExpandidoScreen({super.key, this.latitud, this.longitud});

  @override
  State<MapaExpandidoScreen> createState() => _MapaExpandidoScreenState();
}

class _MapaExpandidoScreenState extends State<MapaExpandidoScreen> {
  late MapaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapaController();

    _controller.onMapaActualizado = () {
      if (mounted) setState(() {});
    };

    _controller.onMostrarDetalle = (alerta) {
      _mostrarDetalleIncidente(alerta);
    };

    _controller.obtenerUbicacionActual();
    _controller.cargarAlertas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mostrarDetalleIncidente(AlertaModel alerta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DetalleIncidenteWidget(
          alerta: alerta,
          controller: _controller,
          onVerEnMapa: () {
            _controller.moverCamara(alerta.latitud, alerta.longitud, 17);
          },
        );
      },
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
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centroInicial,
              zoom: 14.5,
            ),
            markers: _controller.markers,
            myLocationEnabled: _controller.gpsActivo,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller.mapController = controller;
            },
          ),
          _buildTopBar(),
          _buildLegend(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
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
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF2C2C2C),
                size: 24,
              ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      color: _controller.gpsActivo
                          ? const Color(0xFFF4C542)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _controller.gpsActivo ? 'GPS ACTIVO' : 'GPS INACTIVO',
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
    );
  }

  Widget _buildLegend() {
    return Positioned(
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
            _buildLegendItem(const Color(0xFFE84C3D), 'ALTO RIESGO'),
            const SizedBox(height: 6),
            _buildLegendItem(const Color(0xFFF48C42), 'MEDIO RIESGO'),
            const SizedBox(height: 6),
            _buildLegendItem(const Color(0xFFF4C542), 'BAJO RIESGO'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

  Widget _buildBottomBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: Row(
        children: [
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _controller.centrarEnMiUbicacion(),
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
    );
  }
}
