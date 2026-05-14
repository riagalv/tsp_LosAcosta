import 'package:flutter/material.dart';
import '../models/contacto_model.dart';

class FichaTecnicaDialog extends StatelessWidget {
  final Contacto contacto;

  const FichaTecnicaDialog({super.key, required this.contacto});

  /// Muestra la ficha técnica como un BottomSheet.
  static void mostrar(BuildContext context, Contacto contacto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FichaTecnicaDialog(contacto: contacto),
    );
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Seguridad':
        return Icons.local_police;
      case 'Salud':
        return Icons.local_hospital;
      case 'Protección Civil':
        return Icons.fire_truck;
      default:
        return Icons.info;
    }
  }

  Color _colorCategoria(String categoria) {
    switch (categoria) {
      case 'Seguridad':
        return Colors.blue.shade700;
      case 'Salud':
        return Colors.red.shade600;
      case 'Protección Civil':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorCategoria(contacto.categoria);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icono y categoría
          CircleAvatar(
            radius: 32,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_iconoCategoria(contacto.categoria), size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            contacto.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              contacto.categoria,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Funciones
          _FilaInfo(
            icono: Icons.description_outlined,
            titulo: 'Funciones',
            contenido: contacto.funciones,
          ),
          const SizedBox(height: 16),

          // Horario
          _FilaInfo(
            icono: Icons.schedule,
            titulo: 'Horario',
            contenido: contacto.horario,
          ),
          const SizedBox(height: 16),

          // Teléfono
          _FilaInfo(
            icono: Icons.phone,
            titulo: 'Teléfono',
            contenido: contacto.telefono,
          ),

          // Dirección (si existe)
          if (contacto.direccion != null && contacto.direccion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _FilaInfo(
              icono: Icons.location_on_outlined,
              titulo: 'Dirección',
              contenido: contacto.direccion!,
            ),
          ],

          const SizedBox(height: 24),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para mostrar una fila de información.
class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String contenido;

  const _FilaInfo({
    required this.icono,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                contenido,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
