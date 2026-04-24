import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/mapa_controller.dart';
import '../controllers/historial_controller.dart';
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
                  _buildSeccionComunitariaEnTiempoReal(),
                  const SizedBox(height: 24),
                  _buildSeccionValidacion(context),
                  const SizedBox(height: 16),
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

  Widget _buildSeccionComunitariaEnTiempoReal() {
    return StreamBuilder<DocumentSnapshot>(
      // Escuchamos el documento exacto de esta alerta en tiempo real
      stream: FirebaseFirestore.instance.collection('alertas').doc(alerta.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        // Extraemos las validaciones actualizadas
        final confirmaciones = List<String>.from(data['confirmaciones'] ?? []);
        final descartes = List<String>.from(data['descartes'] ?? []);
        final total = confirmaciones.length + descartes.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_reg, size: 22, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'PARTICIPACIÓN COMUNITARIA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2833),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (total == 0)
                Text(
                  'Aún no hay validaciones vecinales.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildEstadisticaParticipacion(
                        titulo: 'Confirmaron',
                        cantidad: confirmaciones.length,
                        color: Colors.green.shade600,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildEstadisticaParticipacion(
                        titulo: 'Descartaron',
                        cantidad: descartes.length,
                        color: Colors.red.shade500,
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticaParticipacion({
    required String titulo,
    required int cantidad,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              cantidad.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSeccionValidacion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿FUISTE TESTIGO?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4A3428),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoValidacion(context, true),
                icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                label: const Text('Sí lo vi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.green.shade300, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoValidacion(context, false),
                icon: const Icon(Icons.visibility_off, color: Colors.red, size: 20),
                label: const Text('No lo vi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _mostrarDialogoValidacion(BuildContext context, bool confirma) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.security, color: Color(0xFFB71C1C), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Confirmar reporte comunitario?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Estás por validar tu participación en este incidente. Tu reporte ayuda a la comunidad a mantenerse informada y segura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _registrarValidacion(context, confirma);
                  },
                  child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF4A3428), fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _registrarValidacion(BuildContext context, bool confirma) async {
    const String userId = 'COLONO_ACTUAL_123'; // Simulación
    if (alerta.id == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFE84C3D))),
    );
    
    try {
      final historialCtrl = HistorialController();
      await historialCtrl.validarAlerta(alerta.id!, userId, confirma);
      
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validación registrada exitosamente. ¡Gracias!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
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