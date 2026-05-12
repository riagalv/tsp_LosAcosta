import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/perro_model.dart';
import '../services/cloudinary_service.dart';

class CatalogoPerrosController {
  final FirebaseFirestore _firestore;

  // Colección en Firestore
  static const String _coleccion = 'perros_callejeros';

  // Municipios válidos para la verificación geográfica
  static const List<String> _municipiosValidos = [
    'Zacatecas',
    'Trancoso',
  ];

  CatalogoPerrosController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── CU-11: DOCUMENTAR PERRO ─────────────────────────────────────────────

  /// Verifica si la posición actual está dentro del municipio de Zacatecas.
  /// Devuelve true si la validación es exitosa.
  Future<bool> verificarMunicipio() async {
    try {
      final posicion = await _obtenerPosicion();
      final placemarks = await placemarkFromCoordinates(
        posicion.latitude,
        posicion.longitude,
      );

      if (placemarks.isNotEmpty) {
        final lugar = placemarks.first;
        final ciudad = lugar.locality ?? '';
        final municipio = lugar.subAdministrativeArea ?? '';

        final textoUbicacion = '$ciudad $municipio'.toLowerCase();
        for (final m in _municipiosValidos) {
          if (textoUbicacion.contains(m.toLowerCase())) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('CatalogoPerrosController.verificarMunicipio: $e');
      return false;
    }
  }

  /// Sube la fotografía a Cloudinary y guarda el perfil del perro en Firestore.
  /// Devuelve el [PerroModel] guardado.
  /// Lanza una excepción en caso de fallo de red o campos inválidos.
  Future<PerroModel> documentarPerro({
    required File foto,
    required String tamanio,
    required String color,
    required String zona,
    String observaciones = '',
  }) async {
    // Obtener identidad del colono desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final telefono = prefs.getString('telefono') ?? 'desconocido';

    // 1. Subir fotografía
    final fotoUrl = await CloudinaryService.subirImagen(foto);

    // 2. Construir modelo
    final perro = PerroModel(
      fotoUrl: fotoUrl,
      tamanio: tamanio,
      color: color,
      zona: zona,
      observaciones: observaciones,
      registradoPor: telefono,
      fecha: DateTime.now(),
    );

    // 3. Guardar en Firestore
    final docRef = await _firestore.collection(_coleccion).add(perro.toMap());
    debugPrint('Perro guardado con id: ${docRef.id}');

    return PerroModel.fromFirestore(await docRef.get());
  }

  // ── CU-12: CONSULTAR CATÁLOGO ────────────────────────────────────────────

  /// Devuelve todos los perfiles registrados, opcionalmente filtrados por zona.
  Future<List<PerroModel>> obtenerCatalogo({String? zona}) async {
    Query query = _firestore
        .collection(_coleccion)
        .orderBy('fecha', descending: true);

    if (zona != null && zona.isNotEmpty) {
      query = query.where('zona', isEqualTo: zona);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PerroModel.fromFirestore(doc))
        .toList();
  }

  /// Devuelve las zonas únicas registradas en el catálogo, para el filtro de CU-12.
  Future<List<String>> obtenerZonas() async {
    final snapshot = await _firestore.collection(_coleccion).get();
    final zonas = snapshot.docs
        .map((doc) => (doc.data()['zona'] as String?) ?? '')
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return zonas;
  }

  /// Registra el voto del colono sobre un perfil de perro.
  /// [esAgresivo] = true → voto "Agresivo"; false → voto "No agresivo".
  /// Lanza [VotoDuplicadoException] si el colono ya votó en este perfil.
  Future<PerroModel> registrarVoto({
    required PerroModel perro,
    required bool esAgresivo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final telefono = prefs.getString('telefono') ?? 'desconocido';

    // FE1: Verificar voto duplicado
    if (perro.votantes.contains(telefono)) {
      throw VotoDuplicadoException();
    }

    final nuevosVotantes = [...perro.votantes, telefono];
    final nuevosVotosAgresivo =
        esAgresivo ? perro.votosAgresivo + 1 : perro.votosAgresivo;
    final nuevosVotosInofensivo =
        esAgresivo ? perro.votosInofensivo : perro.votosInofensivo + 1;

    // Actualizar en Firestore (transacción atómica)
    await _firestore.collection(_coleccion).doc(perro.id).update({
      'votosAgresivo': nuevosVotosAgresivo,
      'votosInofensivo': nuevosVotosInofensivo,
      'votantes': nuevosVotantes,
    });

    return perro.copyWith(
      votosAgresivo: nuevosVotosAgresivo,
      votosInofensivo: nuevosVotosInofensivo,
      votantes: nuevosVotantes,
    );
  }

  // ── UTILIDADES PRIVADAS ──────────────────────────────────────────────────

  Future<Position> _obtenerPosicion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS deshabilitado');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso denegado permanentemente');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

/// Excepción específica cuando el colono intenta votar más de una vez (FE1 del CU-12).
class VotoDuplicadoException implements Exception {
  final String mensaje = 'Ya emitiste tu voto sobre este perfil.';
}
