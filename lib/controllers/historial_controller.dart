import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alerta_model.dart';

class HistorialController {
  final FirebaseFirestore _db;

  HistorialController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AlertaModel>> obtenerAlertas() {
    return _db
        .collection('alertas')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AlertaModel.fromFirestore(doc);
          }).toList();
        });
  }

  Future<void> validarAlerta(String alertaId, String userId, bool confirma) async {
    final ref = _db.collection('alertas').doc(alertaId);
    
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw Exception("La alerta no existe");
      
      final data = doc.data()!;
      
      // Regla de negocio: El emisor no puede autovalidar
      // Suponemos que el 'emisor' se puede comparar (o si es ID). 
      // Para efectos prácticos, validaremos con userId
      if (data['emisor'] == userId || data['emisor'] == "Anónimo" && userId == "Anónimo") {
        // Excepción atrapada en la UI
        throw Exception("No puedes validar tus propias alertas");
      }

      List<String> confirmaciones = List<String>.from(data['confirmaciones'] ?? []);
      List<String> descartes = List<String>.from(data['descartes'] ?? []);
      
      if (confirmaciones.contains(userId) || descartes.contains(userId)) {
        throw Exception("Ya participaste en la validación de este incidente");
      }
      
      if (confirma) {
        confirmaciones.add(userId);
      } else {
        descartes.add(userId);
      }
      
      transaction.update(ref, {
        'confirmaciones': confirmaciones,
        'descartes': descartes,
      });
    });
  }
}
/*import '../models/alerta_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AlertaModel>> obtenerAlertas() {
    return _db.collection('alertas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AlertaModel.fromFirestore(doc);
      }).toList();
    });
  }
}
*/