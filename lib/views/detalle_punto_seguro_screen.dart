import 'package:flutter/material.dart';
import '../models/punto_seguro_model.dart';
import 'registrar_punto_seguro_screen.dart';

class DetallePuntoSeguroScreen extends StatelessWidget {
  final PuntoSeguro punto;
  const DetallePuntoSeguroScreen({super.key, required this.punto});

  IconData _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'casa':
        return Icons.home_rounded;
      case 'negocio':
        return Icons.work_outline_rounded;
      case 'establecimiento':
        return Icons.domain_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'casa':
        return const Color(0xFFB71C1C);
      case 'negocio':
        return const Color(0xFFE65100);
      case 'establecimiento':
        return const Color(0xFF827717);
      default:
        return const Color(0xFF4A3428);
    }
  }

  String _disponibilidadTexto(String disponibilidad) {
    switch (disponibilidad) {
      case 'Siempre disponible':
        return 'Abierto 24 horas';
      case 'Solo de día':
        return 'Solo de día (8:00 AM - 8:00 PM)';
      case 'Solo de noche':
        return 'Solo de noche (8:00 PM - 8:00 AM)';
      default:
        return disponibilidad;
    }
  }

  bool _estaDisponibleAhora(String disponibilidad) {
    final hora = DateTime.now().hour;
    switch (disponibilidad) {
      case 'Siempre disponible':
        return true;
      case 'Solo de día':
        return hora >= 8 && hora < 20;
      case 'Solo de noche':
        return hora >= 20 || hora < 8;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorPorTipo(punto.tipo);
    final ahora = _estaDisponibleAhora(punto.disponibilidad);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB71C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DETALLES',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB71C1C),
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PUNTO SEGURO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C2833),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta principal de información
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre + ícono de tipo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    punto.nombre,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1C2833),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    punto.tipo,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _iconoPorTipo(punto.tipo),
                                color: color,
                                size: 26,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Disponibilidad
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.access_time_filled,
                                size: 20,
                                color: Color(0xFF4A3428),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DISPONIBILIDAD',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4A3428),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _disponibilidadTexto(
                                            punto.disponibilidad,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF1C2833),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (ahora) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F0DC),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'AHORA',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF827717),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Atributos de seguridad (solo si tiene alguno)
                        if (punto.vigilancia24h || punto.botonPanico) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (punto.vigilancia24h)
                                _buildAtributoChip(
                                  Icons.videocam_outlined,
                                  'VIGILANCIA 24/7',
                                ),
                              if (punto.botonPanico)
                                _buildAtributoChip(
                                  Icons.phone_in_talk_outlined,
                                  'BOTÓN DE PÁNICO',
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón EDITAR fijo al fondo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrarPuntoSeguroScreen(
                        puntoExistente: punto,
                        modoEdicion: true,
                      ),
                    ),
                  );
                  // Al volver, el stream ya actualizó los datos automáticamente
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'EDITAR',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: const Color(0xFF4A3428)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4A3428),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1C2833),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAtributoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4A3428)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A3428),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
