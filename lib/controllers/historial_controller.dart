import '../models/alerta_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Alerta>> obtenerAlertas() {
    return _db.collection('alertas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Alerta.fromFirestore(doc);
      }).toList();
    });
  }
}
