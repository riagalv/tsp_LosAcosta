import 'package:flutter/material.dart';
import '../controllers/punto_seguro_controller.dart';
import '../models/punto_seguro_model.dart';
import '../services/usuario_service.dart';
import 'detalle_punto_seguro_screen.dart';
import 'registrar_punto_seguro_screen.dart';

class MisPuntosSegurosScreen extends StatelessWidget {
  const MisPuntosSegurosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PuntoSeguroController();
    final userId = UsuarioService.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PUNTOS SEGUROS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistrarPuntoSeguroScreen(),
                ),
              ),
              icon: const Icon(Icons.add, color: Color(0xFFB71C1C), size: 20),
              label: const Text(
                'NUEVO',
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<PuntoSeguro>>(
        stream: controller.obtenerMisPuntos(userId),
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            );
          }

          // Error de conexión
          if (snapshot.hasError) {
            return _buildEstadoVacio(
              icon: Icons.wifi_off_rounded,
              titulo: 'Sin conexión',
              subtitulo:
                  'No se pudo cargar tu lista de puntos seguros.\nVerifica tu conexión a internet.',
              color: Colors.red.shade300,
            );
          }

          final puntos = snapshot.data ?? [];

          // FE3 — Sin puntos registrados
          if (puntos.isEmpty) {
            return _buildEstadoVacio(
              icon: Icons.shield_outlined,
              titulo: 'Sin puntos registrados',
              subtitulo:
                  'Aún no has registrado ningún punto seguro.\nToca "+ NUEVO" para agregar el primero.',
              color: Colors.grey.shade400,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _SeccionTitulo(titulo: 'Lugares de Confianza'),
              const SizedBox(height: 16),
              ...puntos.map(
                (punto) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PuntoSeguroCard(
                    punto: punto,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetallePuntoSeguroScreen(punto: punto),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEstadoVacio({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección título con línea roja ───────────────────────────────────────────
class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  const _SeccionTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C2833),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de punto seguro ──────────────────────────────────────────────────
class _PuntoSeguroCard extends StatelessWidget {
  final PuntoSeguro punto;
  final VoidCallback onTap;

  const _PuntoSeguroCard({required this.punto, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final color = _colorPorTipo(punto.tipo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de tipo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconoPorTipo(punto.tipo), color: color, size: 26),
            ),
            const SizedBox(width: 16),

            // Nombre, tipo y dirección
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    punto.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2833),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    punto.tipo.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Menú contextual
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'ver') onTap();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'ver',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Ver detalles'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
