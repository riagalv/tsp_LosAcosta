import 'package:cloud_firestore/cloud_firestore.dart';

class AlertaModel {
  final String? id; // Opcional: para cuando se crea no tiene id, para leer sí
  final double latitud;
  final double longitud;
  final String direccion;
  final String riesgo;
  final String estado;
  final String emisor;
  final DateTime? fecha;
  final List<String> confirmaciones;
  final List<String> descartes;

  AlertaModel({
    this.id,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.riesgo,
    required this.estado,
    required this.emisor,
    this.fecha,
    this.confirmaciones = const [],
    this.descartes = const [],
  });

  // GUARDAR en Firestore (NO incluye id)
  Map<String, dynamic> toMap() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'riesgo': riesgo,
      'estado': estado,
      'emisor': emisor,
      'fecha': fecha ?? FieldValue.serverTimestamp(),
      'confirmaciones': confirmaciones,
      'descartes': descartes,
    };
  }

  //Para LEER desde Firestore (incluye id)
  factory AlertaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AlertaModel(
      id: doc.id,
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      direccion: data['direccion'] ?? '',
      riesgo: data['riesgo'] ?? '',
      estado: data['estado'] ?? '',
      emisor: data['emisor'] ?? 'Anónimo',
      fecha: data['fecha']?.toDate(),
      confirmaciones: List<String>.from(data['confirmaciones'] ?? []),
      descartes: List<String>.from(data['descartes'] ?? []),
    );
  }

  // Para convertir desde Map (alternativa si lo necesitas)
  factory AlertaModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AlertaModel(
      id: id,
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      direccion: map['direccion'] ?? '',
      riesgo: map['riesgo'] ?? '',
      estado: map['estado'] ?? '',
      emisor: map['emisor'] ?? 'Anónimo',
      fecha: map['fecha']?.toDate(),
      confirmaciones: List<String>.from(map['confirmaciones'] ?? []),
      descartes: List<String>.from(map['descartes'] ?? []),
    );
  }
}
/*import 'package:cloud_firestore/cloud_firestore.dart';

class Alerta {
  final String id;
  final String direccion;
  final String riesgo;
  final String estado;
  final Timestamp fecha;
  final double latitud;
  final double longitud;
  final String emisor;

  Alerta({
    required this.id,
    required this.direccion,
    required this.riesgo,
    required this.estado,
    required this.fecha,
    required this.latitud,
    required this.longitud,
    required this.emisor,
  });

  factory Alerta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Alerta(
      id: doc.id,
      direccion: data['direccion'] ?? '',
      riesgo: data['riesgo'] ?? '',
      estado: data['estado'] ?? '',
      fecha: data['fecha'] ?? Timestamp.now(),
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      emisor: data['emisor'] ?? 'Anónimo',
    );
  }
}
*/