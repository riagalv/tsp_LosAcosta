import 'package:flutter/material.dart';
import '../controllers/historial_controller.dart';
import '../models/alerta_model.dart';

class HistorialScreen extends StatelessWidget {
  final HistorialController controller = HistorialController();

  HistorialScreen({super.key});

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';
    // Formato: 12 MAYO
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  String _formatearHora(DateTime? fecha) {
    if (fecha == null) return 'Hora no disponible';
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto hrs';
  }

  Color _getColorPorRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return const Color(0xFFE84C3D); // Rojo
      case 'MEDIO':
        return const Color(0xFFF48C42); // Naranja
      case 'BAJO':
        return const Color(0xFFF4C542); // Amarillo
      default:
        return const Color(0xFFF48C42);
    }
  }

  String _getTextoRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return 'ALTO RIESGO';
      case 'MEDIO':
        return 'MEDIO RIESGO';
      case 'BAJO':
        return 'BAJO RIESGO';
      default:
        return riesgo.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Historial"),
        backgroundColor: const Color(0xFF1C2833),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Subtítulo / descripción
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Registro de alertas emitidas y reportes de seguridad en tu zona.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          // Lista de alertas
          Expanded(
            child: StreamBuilder<List<AlertaModel>>(
              stream: controller.obtenerAlertas(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text("Error al cargar: ${snapshot.error}"),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alertas = snapshot.data!;

                if (alertas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No hay registros todavía",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = alertas[index];
                    final fechaFormateada = _formatearFecha(alerta.fecha);
                    final colorRiesgo = _getColorPorRiesgo(alerta.riesgo);
                    final textoRiesgo = _getTextoRiesgo(alerta.riesgo);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: colorRiesgo, width: 6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fecha
                              Text(
                                fechaFormateada,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1C2833),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Dirección (ahora muestra la calle guardada)
                              Text(
                                alerta.direccion,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Badge de riesgo
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorRiesgo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  textoRiesgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorRiesgo,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Fila inferior: estado + botón detalles
                              Row(
                                children: [
                                  // Estado sincronizado
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: const Color(0xFFE84C3D),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'SINCRONIZADO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE84C3D),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Botón detalles
                                  TextButton(
                                    onPressed: () {
                                      _mostrarDetalles(context, alerta);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DETALLES',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFF48C42),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: Color(0xFFF48C42),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalles(BuildContext context, AlertaModel alerta) {
    final colorRiesgo = _getColorPorRiesgo(alerta.riesgo);
    final fechaFormateada = _formatearFecha(alerta.fecha);
    final horaFormateada = _formatearHora(alerta.fecha);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 24),
                      // Fecha
                      Text(
                        fechaFormateada,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C2833),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dirección (calle legible)
                      Text(
                        alerta.direccion,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Badge riesgo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorRiesgo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _getTextoRiesgo(alerta.riesgo),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorRiesgo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Información adicional
                      _buildDetalleFila(
                        icon: Icons.person_outline,
                        titulo: 'EMISOR',
                        contenido: alerta.emisor,
                      ),
                      const SizedBox(height: 16),
                      _buildDetalleFila(
                        icon: Icons.access_time,
                        titulo: 'HORA',
                        contenido: horaFormateada,
                      ),
                      const SizedBox(height: 16),
                      _buildDetalleFila(
                        icon: Icons.location_on_outlined,
                        titulo: 'UBICACIÓN EXACTA',
                        contenido:
                            '${alerta.latitud.toStringAsFixed(6)}, ${alerta.longitud.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 24),
                      // Botón cerrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C2833),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'CERRAR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDetalleFila({
    required IconData icon,
    required String titulo,
    required String contenido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contenido,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2833),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
/*import 'package:flutter/material.dart';
import '../controllers/historial_controller.dart';
import '../models/alerta_model.dart';

class HistorialScreen extends StatelessWidget {
  final HistorialController controller = HistorialController();

  HistorialScreen({super.key});

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';
    // Formato: 12 MAYO
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  Color _getColorPorRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return const Color(0xFFE84C3D); // Rojo
      case 'MEDIO':
        return const Color(0xFFF48C42); // Naranja
      case 'BAJO':
        return const Color(0xFFF4C542); // Amarillo
      default:
        return const Color(0xFFF48C42);
    }
  }

  String _getTextoRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return 'ALTO RIESGO';
      case 'MEDIO':
        return 'MEDIO RIESGO';
      case 'BAJO':
        return 'BAJO RIESGO';
      default:
        return riesgo.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Historial"),
        backgroundColor: const Color(0xFF1C2833),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Subtítulo / descripción
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Registro de alertas emitidas y reportes de seguridad en tu zona.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          // Lista de alertas
          Expanded(
            child: StreamBuilder<List<AlertaModel>>(
              stream: controller.obtenerAlertas(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text("Error al cargar: ${snapshot.error}"),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alertas = snapshot.data!;

                if (alertas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No hay registros todavía",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = alertas[index];
                    final fecha = alerta.fecha ?? DateTime.now();
                    final fechaFormateada = _formatearFecha(alerta.fecha);
                    final colorRiesgo = _getColorPorRiesgo(alerta.riesgo);
                    final textoRiesgo = _getTextoRiesgo(alerta.riesgo);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: colorRiesgo, width: 6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fecha
                              Text(
                                fechaFormateada,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1C2833),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Dirección
                              Text(
                                alerta.direccion,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Badge de riesgo
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorRiesgo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  textoRiesgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorRiesgo,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Fila inferior: estado + botón detalles
                              Row(
                                children: [
                                  // Estado sincronizado
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: const Color(0xFFE84C3D),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'SINCRONIZADO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE84C3D),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Botón detalles
                                  TextButton(
                                    onPressed: () {
                                      _mostrarDetalles(context, alerta);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DETALLES',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFF48C42),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: Color(0xFFF48C42),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalles(BuildContext context, AlertaModel alerta) {
    final colorRiesgo = _getColorPorRiesgo(alerta.riesgo);
    final fechaFormateada = _formatearFecha(alerta.fecha);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 24),
                      // Fecha
                      Text(
                        fechaFormateada,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C2833),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dirección
                      Text(
                        alerta.direccion,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Badge riesgo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorRiesgo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _getTextoRiesgo(alerta.riesgo),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorRiesgo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Información adicional
                      _buildDetalleFila(
                        icon: Icons.person_outline,
                        titulo: 'EMISOR',
                        contenido: alerta.emisor,
                      ),
                      const SizedBox(height: 16),
                      _buildDetalleFila(
                        icon: Icons.access_time,
                        titulo: 'HORA',
                        contenido:
                            '${alerta.fecha?.hour.toString().padLeft(2, '0')}:${alerta.fecha?.minute.toString().padLeft(2, '0')} hrs',
                      ),
                      const SizedBox(height: 16),
                      _buildDetalleFila(
                        icon: Icons.location_on_outlined,
                        titulo: 'UBICACIÓN',
                        contenido:
                            '${alerta.latitud.toStringAsFixed(4)}, ${alerta.longitud.toStringAsFixed(4)}',
                      ),
                      const SizedBox(height: 24),
                      // Botón cerrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C2833),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'CERRAR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDetalleFila({
    required IconData icon,
    required String titulo,
    required String contenido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contenido,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2833),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}*/
/*import 'package:flutter/material.dart';
import '../controllers/historial_controller.dart';
import '../models/alerta_model.dart';

class HistorialScreen extends StatelessWidget {
  final HistorialController controller = HistorialController();

  HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Historial")),
      body: StreamBuilder<List<AlertaModel>>(
        stream: controller.obtenerAlertas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertas = snapshot.data!;

          if (alertas.isEmpty) {
            return const Center(child: Text("No hay registros todavía"));
          }

          return ListView.builder(
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final alerta = alertas[index];
              // ✅ alerta.fecha ya es DateTime?, no necesita .toDate()
              final fecha = alerta.fecha ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(alerta.direccion),
                  subtitle: Text("${fecha.day}/${fecha.month}/${fecha.year}"),
                  trailing: Text(alerta.riesgo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/
/*import 'package:flutter/material.dart';
import '../controllers/historial_controller.dart';
import '../models/alerta_model.dart';

class HistorialScreen extends StatelessWidget {
  final HistorialController controller = HistorialController();

  HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Historial")),

      body: StreamBuilder<List<AlertaModel>>(
        stream: controller.obtenerAlertas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertas = snapshot.data!;

          if (alertas.isEmpty) {
            return const Center(child: Text("No hay registros todavía"));
          }

          return ListView.builder(
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final alerta = alertas[index];
              final fecha = alerta.fecha.toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(alerta.direccion),
                  subtitle: Text("${fecha.day}/${fecha.month}/${fecha.year}"),
                  trailing: Text(alerta.riesgo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
*/