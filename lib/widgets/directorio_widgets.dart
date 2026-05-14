import 'package:flutter/material.dart';
import '../models/contacto_model.dart';
import '../views/ficha_tecnica_dialog.dart';

// Configuración de categorías (centralizada)
class CategoriaConfig {
  static const Map<String, Map<String, dynamic>> datos = {
    'Seguridad': {
      'icono': Icons.local_police,
      'color': Color(0xFF1976D2), // Azul
    },
    'Salud': {
      'icono': Icons.local_hospital,
      'color': Color(0xFFD32F2F), // Rojo
    },
    'Protección Civil': {
      'icono': Icons.fire_truck,
      'color': Color(0xFFF57C00), // Naranja
    },
  };

  static IconData getIcono(String categoria) {
    return datos[categoria]?['icono'] ?? Icons.info;
  }

  static Color getColor(String categoria) {
    return datos[categoria]?['color'] ?? Colors.grey.shade700;
  }
}

// Chip de categoría reutilizable
class CategoriaChip extends StatelessWidget {
  final String categoria;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoriaChip({
    super.key,
    required this.categoria,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoriaConfig.getColor(categoria);
    final icono = CategoriaConfig.getIcono(categoria);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: Icon(icono, size: 18, color: isSelected ? Colors.white : color),
        label: Text(categoria),
        selected: isSelected,
        selectedColor: color,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

// Tarjeta de contacto reutilizable
class ContactoTarjeta extends StatelessWidget {
  final Contacto contacto;

  const ContactoTarjeta({super.key, required this.contacto});

  @override
  Widget build(BuildContext context) {
    final color = CategoriaConfig.getColor(contacto.categoria);
    final icono = CategoriaConfig.getIcono(contacto.categoria);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icono, color: color, size: 22),
        ),
        title: Text(
          contacto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          contacto.telefono,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => FichaTecnicaDialog.mostrar(context, contacto),
      ),
    );
  }
}

// Barra de búsqueda reutilizable
class BarraBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final String filtro;

  const BarraBusqueda({
    super.key,
    required this.controller,
    required this.filtro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: filtro.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}

// Widget para cuando no hay resultados
class SinResultadosWidget extends StatelessWidget {
  const SinResultadosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Sin coincidencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró ninguna institución.\nEn caso de emergencia, llama al 911.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Emergencias: 911',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
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
}
