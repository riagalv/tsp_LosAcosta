import 'package:cloud_firestore/cloud_firestore.dart';

class PerroModel {
  final String? id;
  final String fotoUrl;
  final String tamanio; // Pequeño, Mediano, Grande
  final String color;
  final String zona;
  final String observaciones;
  final String registradoPor; // Teléfono del colono que lo registró
  final DateTime? fecha;
  final int votosAgresivo;
  final int votosInofensivo;
  final List<String> votantes; // Lista de teléfonos que ya votaron

  PerroModel({
    this.id,
    required this.fotoUrl,
    required this.tamanio,
    required this.color,
    required this.zona,
    this.observaciones = '',
    required this.registradoPor,
    this.fecha,
    this.votosAgresivo = 0,
    this.votosInofensivo = 0,
    this.votantes = const [],
  });

  /// Calcula el nivel de agresividad como etiqueta según la especificación CU-12
  String get nivelAgresividad {
    final total = votosAgresivo + votosInofensivo;
    if (total == 0) return 'Sin votos';
    final porcentaje = (votosAgresivo / total) * 100;
    if (porcentaje >= 67) return 'PELIGROSO';
    if (porcentaje >= 34) return 'MODERADO';
    return 'INOFENSIVO';
  }

  int get totalVotos => votosAgresivo + votosInofensivo;

  // Guardar en Firestore (sin id)
  Map<String, dynamic> toMap() {
    return {
      'fotoUrl': fotoUrl,
      'tamanio': tamanio,
      'color': color,
      'zona': zona,
      'observaciones': observaciones,
      'registradoPor': registradoPor,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : FieldValue.serverTimestamp(),
      'votosAgresivo': votosAgresivo,
      'votosInofensivo': votosInofensivo,
      'votantes': votantes,
    };
  }

  // Leer desde Firestore (con id)
  factory PerroModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PerroModel(
      id: doc.id,
      fotoUrl: data['fotoUrl'] ?? '',
      tamanio: data['tamanio'] ?? '',
      color: data['color'] ?? '',
      zona: data['zona'] ?? '',
      observaciones: data['observaciones'] ?? '',
      registradoPor: data['registradoPor'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
      votosAgresivo: data['votosAgresivo'] ?? 0,
      votosInofensivo: data['votosInofensivo'] ?? 0,
      votantes: List<String>.from(data['votantes'] ?? []),
    );
  }

  // Copia con campos modificados (útil para actualizaciones de votos)
  PerroModel copyWith({
    int? votosAgresivo,
    int? votosInofensivo,
    List<String>? votantes,
  }) {
    return PerroModel(
      id: id,
      fotoUrl: fotoUrl,
      tamanio: tamanio,
      color: color,
      zona: zona,
      observaciones: observaciones,
      registradoPor: registradoPor,
      fecha: fecha,
      votosAgresivo: votosAgresivo ?? this.votosAgresivo,
      votosInofensivo: votosInofensivo ?? this.votosInofensivo,
      votantes: votantes ?? this.votantes,
    );
  }
}
