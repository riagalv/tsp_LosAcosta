import 'package:cloud_firestore/cloud_firestore.dart';

class PuntoSeguro {
  final String id;
  final String nombre;
  final String tipo;
  final String direccion;
  final String disponibilidad;
  final double latitud;
  final double longitud;
  final String userId;
  final bool vigilancia24h;
  final bool botonPanico;
  final DateTime? fechaRegistro;

  const PuntoSeguro({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.direccion,
    required this.disponibilidad,
    required this.latitud,
    required this.longitud,
    required this.userId,
    this.vigilancia24h = false,
    this.botonPanico = false,
    this.fechaRegistro,
  });

  factory PuntoSeguro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PuntoSeguro(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      tipo: data['tipo'] as String? ?? '',
      direccion: data['direccion'] as String? ?? '',
      disponibilidad: data['disponibilidad'] as String? ?? '',
      latitud: (data['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (data['longitud'] as num?)?.toDouble() ?? 0.0,
      userId: data['userId'] as String? ?? '',
      vigilancia24h: data['vigilancia24h'] as bool? ?? false,
      botonPanico: data['botonPanico'] as bool? ?? false,
      fechaRegistro: (data['fecha_registro'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'direccion': direccion,
      'disponibilidad': disponibilidad,
      'latitud': latitud,
      'longitud': longitud,
      'userId': userId,
      'vigilancia24h': vigilancia24h,
      'botonPanico': botonPanico,
    };
  }
}
