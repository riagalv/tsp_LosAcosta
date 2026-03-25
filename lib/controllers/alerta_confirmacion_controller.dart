import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alerta_model.dart';
import '../services/ubicacion_service.dart';

class AlertaConfirmacionController {
  final UbicacionService _ubicacionService = UbicacionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Propiedad para almacenar el nivel de riesgo
  final String nivelRiesgo;

  String? ubicacionTexto;
  bool cargando = true;
  Position? posicion;

  // Callbacks para actualizar la vista
  Function? onUbicacionActualizada;
  Function? onError;

  // Recibe nivelRiesgo en el constructor
  AlertaConfirmacionController({required this.nivelRiesgo});

  Future<void> obtenerUbicacion() async {
    try {
      final posicion = await _ubicacionService.obtenerUbicacionActual();

      final direccionLegible = await _obtenerDireccionDesdeCoordenadas(
        posicion.latitude,
        posicion.longitude,
      );

      ubicacionTexto = direccionLegible;
      this.posicion = posicion;
      cargando = false;

      if (onUbicacionActualizada != null) {
        onUbicacionActualizada!();
      }

      // Guardar alerta con dirección legible
      await guardarAlerta(posicion, direccionLegible);
    } catch (e) {
      cargando = false;
      ubicacionTexto = e.toString();

      if (onError != null) {
        onError!();
      }
    }
  }

  /// Convierte coordenadas a dirección legible (calle, colonia, ciudad)
  Future<String> _obtenerDireccionDesdeCoordenadas(
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

        // Calle
        if (place.street != null && place.street!.isNotEmpty) {
          partes.add(place.street!);
        }
        // Número exterior (si está disponible)
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          if (partes.isNotEmpty) {
            partes[partes.length - 1] =
                '${partes.last} ${place.subThoroughfare}';
          } else {
            partes.add(place.subThoroughfare!);
          }
        }
        // Colonia / SubLocalidad
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          partes.add(place.subLocality!);
        }
        // Ciudad / Localidad
        if (place.locality != null && place.locality!.isNotEmpty) {
          partes.add(place.locality!);
        }
        // Estado (opcional, si quieres más detalle)
        // if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        //   partes.add(place.administrativeArea!);
        // }

        if (partes.isNotEmpty) {
          return partes.join(', ');
        }

        // Si no hay calle, mostrar al menos colonia o ciudad
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
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

  // Guardar alerta con dirección legible
  Future<void> guardarAlerta(Position posicion, String direccionLegible) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('nombre') ?? '';
      final apellido = prefs.getString('apellido') ?? '';
      final emisor = '$nombre $apellido'.trim();

      final alerta = AlertaModel(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        direccion: direccionLegible,
        riesgo: nivelRiesgo,
        estado: 'activa',
        emisor: emisor.isNotEmpty ? emisor : 'Anónimo',
      );

      await _firestore.collection('alertas').add(alerta.toMap());
      debugPrint('Alerta guardada con dirección: $direccionLegible');
    } catch (e) {
      debugPrint('Error guardando alerta: $e');
      rethrow;
    }
  }
}
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alerta_model.dart';
import '../services/ubicacion_service.dart';

class AlertaConfirmacionController {
  final UbicacionService _ubicacionService = UbicacionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agrega esta propiedad para almacenar el nivel de riesgo
  final String nivelRiesgo;

  String? ubicacionTexto;
  bool cargando = true;
  Position? posicion;

  // Callbacks para actualizar la vista
  Function? onUbicacionActualizada;
  Function? onError;

  // Recibe nivelRiesgo en el constructor
  AlertaConfirmacionController({required this.nivelRiesgo});

  Future<void> obtenerUbicacion() async {
    try {
      final posicion = await _ubicacionService.obtenerUbicacionActual();
      ubicacionTexto = _ubicacionService.obtenerTextoUbicacion(posicion);
      this.posicion = posicion;
      cargando = false;

      if (onUbicacionActualizada != null) {
        onUbicacionActualizada!();
      }

      // Pasa el nivelRiesgo correctamente
      await guardarAlerta(posicion);
    } catch (e) {
      cargando = false;
      ubicacionTexto = e.toString();

      if (onError != null) {
        onError!();
      }
    }
  }

  // Elimina el parámetro nivelRiesgo de aquí porque ya lo tienes como propiedad
  Future<void> guardarAlerta(Position posicion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('nombre') ?? '';
      final apellido = prefs.getString('apellido') ?? '';
      final emisor = '$nombre $apellido'.trim();

      final alerta = AlertaModel(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        direccion: ubicacionTexto ?? '',
        riesgo: nivelRiesgo, // Usa la propiedad de la clase
        estado: 'activa',
        emisor: emisor.isNotEmpty ? emisor : 'Anónimo',
      );

      await _firestore.collection('alertas').add(alerta.toMap());
    } catch (e) {
      debugPrint('Error guardando alerta: $e');
      rethrow;
    }
  }
}*/