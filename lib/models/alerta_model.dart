import 'package:cloud_firestore/cloud_firestore.dart';

class Alerta {
  final String id;
  final String direccion;
  final String riesgo;
  final String estado;
  final Timestamp fecha;

  Alerta({
    required this.id,
    required this.direccion,
    required this.riesgo,
    required this.estado,
    required this.fecha,
  });

  factory Alerta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Alerta(
      id: doc.id,
      direccion: data['direccion'] ?? '',
      riesgo: data['riesgo'] ?? '',
      estado: data['estado'] ?? '',
      fecha: data['fecha'] ?? Timestamp.now(),
    );
  }
}
