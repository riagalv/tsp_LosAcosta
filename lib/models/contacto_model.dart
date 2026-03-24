import 'package:cloud_firestore/cloud_firestore.dart';

class Contacto {
  final String id;
  final String nombre;
  final String categoria;
  final String telefono;
  final String horario;
  final String funciones;
  final String? direccion;

  Contacto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.telefono,
    required this.horario,
    required this.funciones,
    this.direccion,
  });

  factory Contacto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contacto(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      telefono: data['telefono'] ?? '',
      horario: data['horario'] ?? '',
      funciones: data['funciones'] ?? '',
      direccion: data['direccion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'telefono': telefono,
      'horario': horario,
      'funciones': funciones,
      'direccion': direccion,
    };
  }
}
