import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ubicacion_service.dart';

class AlertaModel {
  final double latitud;
  final double longitud;
  final String direccion;
  final String riesgo;
  final String estado;
  final String emisor;
  final DateTime? fecha;

  AlertaModel({
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.riesgo,
    required this.estado,
    required this.emisor,
    this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'riesgo': riesgo,
      'estado': estado,
      'emisor': emisor,
      'fecha': fecha ?? FieldValue.serverTimestamp(),
    };
  }

  factory AlertaModel.fromMap(Map<String, dynamic> map) {
    return AlertaModel(
      latitud: map['latitud'],
      longitud: map['longitud'],
      direccion: map['direccion'],
      riesgo: map['riesgo'],
      estado: map['estado'],
      emisor: map['emisor'],
      fecha: map['fecha']?.toDate(),
    );
  }
}
