import 'package:cloud_firestore/cloud_firestore.dart';
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
}
/*
class AlertaConfirmacionController {
  final UbicacionService _ubicacionService = UbicacionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? ubicacionTexto;
  bool cargando = true;
  Position? posicion;

  // Callbacks para actualizar la vista
  Function? onUbicacionActualizada;
  Function? onError;

  Future<void> obtenerUbicacion() async {
    try {
      final posicion = await _ubicacionService.obtenerUbicacionActual();
      ubicacionTexto = _ubicacionService.obtenerTextoUbicacion(posicion);
      this.posicion = posicion;
      cargando = false;
      
      if (onUbicacionActualizada != null) {
        onUbicacionActualizada!();
      }
      
      await guardarAlerta(posicion);
    } catch (e) {
      cargando = false;
      ubicacionTexto = e.toString();
      
      if (onError != null) {
        onError!();
      }
    }
  }

  Future<void> guardarAlerta(Position posicion, {required String nivelRiesgo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('nombre') ?? '';
      final apellido = prefs.getString('apellido') ?? '';
      final emisor = '$nombre $apellido'.trim();

      final alerta = AlertaModel(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        direccion: ubicacionTexto ?? '',
        riesgo: nivelRiesgo,
        estado: 'activa',
        emisor: emisor.isNotEmpty ? emisor : 'Anónimo',
      );

      await _firestore.collection('alertas').add(alerta.toMap());
    } catch (e) {
      print('Error guardando alerta: $e');
      rethrow;
    }
  }
}*/