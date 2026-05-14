import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/punto_seguro_model.dart';

class PuntoSeguroController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'puntos_seguros';

  /// Obtiene en tiempo real los puntos seguros del usuario actual.
  Stream<List<PuntoSeguro>> obtenerMisPuntos(String userId) {
    return _firestore
        .collection(_coleccion)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PuntoSeguro.fromFirestore(doc)).toList());
  }

  /// Actualiza los campos modificables de un punto seguro existente.
  Future<void> actualizarPuntoSeguro({
    required String id,
    required String nombre,
    required String tipo,
    required String direccion,
    required String disponibilidad,
    required double latitud,
    required double longitud,
    required bool vigilancia24h,
    required bool botonPanico,
  }) async {
    await _firestore.collection(_coleccion).doc(id).update({
      'nombre': nombre,
      'tipo': tipo,
      'direccion': direccion,
      'disponibilidad': disponibilidad,
      'latitud': latitud,
      'longitud': longitud,
      'vigilancia24h': vigilancia24h,
      'botonPanico': botonPanico,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Verifica si el usuario ya votó en este punto seguro.
  /// Devuelve null si no ha votado, true si confirmó, false si descartó.
  Future<bool?> obtenerVotoUsuario(String puntoId, String userId) async {
    final doc = await _firestore
        .collection(_coleccion)
        .doc(puntoId)
        .collection('validaciones')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['voto'] as bool?;
  }

  /// Registra el voto del usuario (true = seguro, false = no existe).
  /// Actualiza los contadores del punto con una transacción atómica.
  Future<void> registrarVoto({
    required String puntoId,
    required String userId,
    required bool esSeguro,
  }) async {
    final puntoRef = _firestore.collection(_coleccion).doc(puntoId);
    final votoRef = puntoRef.collection('validaciones').doc(userId);

    await _firestore.runTransaction((tx) async {
      final votoSnap = await tx.get(votoRef);

      // Si ya votó, no hacer nada (doble protección)
      if (votoSnap.exists) throw Exception('Ya emitiste tu opinión sobre este punto seguro.');

      tx.set(votoRef, {
        'voto': esSeguro,
        'fecha': FieldValue.serverTimestamp(),
      });

      tx.update(puntoRef, {
        if (esSeguro) 'confirmaciones': FieldValue.increment(1)
        else 'descartes': FieldValue.increment(1),
      });
    });
  }
}
