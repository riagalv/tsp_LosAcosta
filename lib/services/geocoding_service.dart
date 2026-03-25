import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class GeocodingService {
  /// Convierte coordenadas a nombre de calle/dirección
  static Future<String> obtenerDireccionDesdeCoordenadas(
    double latitud,
    double longitud,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitud,
        longitud,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Construir dirección legible
        final List<String> partes = [];

        if (place.street != null && place.street!.isNotEmpty) {
          partes.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          partes.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          partes.add(place.locality!);
        }

        if (partes.isNotEmpty) {
          return partes.join(', ');
        }

        // Si no hay calle, mostrar colonia y ciudad
        if (place.subAdministrativeArea != null) {
          return place.subAdministrativeArea!;
        }
      }

      // Fallback: mostrar coordenadas
      return '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Error en geocodificación: $e');
      return '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}';
    }
  }
}
