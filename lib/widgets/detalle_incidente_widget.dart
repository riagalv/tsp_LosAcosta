import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/mapa_controller.dart';
import '../models/alerta_model.dart';

class DetalleIncidenteWidget extends StatelessWidget {
  final AlertaModel alerta;
  final MapaController controller;
  final VoidCallback onVerEnMapa;

  const DetalleIncidenteWidget({
    super.key,
    required this.alerta,
    required this.controller,
    required this.onVerEnMapa,
  });

  @override
  Widget build(BuildContext context) {
    final color = controller.getColorPorRiesgo(alerta.riesgo);

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
                  _buildHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Detalles del Incidente',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C2833),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUbicacion(),
                  const SizedBox(height: 20),
                  _buildRiesgoCard(color),
                  const SizedBox(height: 14),
                  _buildHoraEmisor(),
                  const SizedBox(height: 14),
                  _buildAlcance(),
                  const SizedBox(height: 20),
                  _buildBotonVerEnMapa(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildUbicacion() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            alerta.direccion.isNotEmpty
                ? alerta.direccion
                : '${alerta.latitud.toStringAsFixed(4)}, ${alerta.longitud.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildRiesgoCard(Color color) {
    return Container(
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
            child: Icon(Icons.warning_rounded, color: color, size: 26),
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
                  controller.getEtiquetaRiesgo(alerta.riesgo),
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
    );
  }

  Widget _buildHoraEmisor() {
    // Convertir DateTime a Timestamp para usar getTiempoTranscurrido
    final fechaTimestamp = Timestamp.fromDate(alerta.fecha ?? DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time,
                  size: 22,
                  color: Colors.orange.shade300,
                ),
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
                  controller.getTiempoTranscurrido(fechaTimestamp),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person, size: 22, color: Colors.brown.shade300),
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
    );
  }

  Widget _buildAlcance() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 32,
            child: Stack(
              children: [
                _buildAvatar(),
                Positioned(left: 18, child: _buildAvatar()),
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
          Icon(Icons.groups, size: 28, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.brown.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }

  Widget _buildBotonVerEnMapa(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onVerEnMapa();
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
    );
  }
}
/*import 'package:flutter/material.dart';
import '../controllers/mapa_controller.dart';
import '../models/alerta_model.dart';

class DetalleIncidenteWidget extends StatelessWidget {
  final AlertaModel alerta;
  final MapaController controller;
  final VoidCallback onVerEnMapa;

  const DetalleIncidenteWidget({
    super.key,
    required this.alerta,
    required this.controller,
    required this.onVerEnMapa,
  });

  @override
  Widget build(BuildContext context) {
    final color = controller.getColorPorRiesgo(alerta.riesgo);

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
                  _buildHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Detalles del Incidente',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C2833),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUbicacion(),
                  const SizedBox(height: 20),
                  _buildRiesgoCard(color),
                  const SizedBox(height: 14),
                  _buildHoraEmisor(),
                  const SizedBox(height: 14),
                  _buildAlcance(),
                  const SizedBox(height: 20),
                  _buildBotonVerEnMapa(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildUbicacion() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            alerta.direccion.isNotEmpty
                ? alerta.direccion
                : '${alerta.latitud.toStringAsFixed(4)}, ${alerta.longitud.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildRiesgoCard(Color color) {
    return Container(
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
            child: Icon(Icons.warning_rounded, color: color, size: 26),
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
                  controller.getEtiquetaRiesgo(alerta.riesgo),
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
    );
  }

  Widget _buildHoraEmisor() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time, size: 22, color: Colors.orange.shade300),
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
                  controller.getTiempoTranscurrido(alerta.fecha!),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person, size: 22, color: Colors.brown.shade300),
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
    );
  }

  Widget _buildAlcance() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 32,
            child: Stack(
              children: [
                _buildAvatar(),
                const Positioned(left: 18, child: _buildAvatar()),
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
          Icon(Icons.groups, size: 28, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.brown.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }

  Widget _buildBotonVerEnMapa(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onVerEnMapa();
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
    );
  }
}*/