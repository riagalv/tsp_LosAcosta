import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contacto_model.dart';

class DirectorioController {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _coleccion;

  DirectorioController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _coleccion = _firestore.collection('directorio');
  }

  /// Obtiene todos los contactos en tiempo real.
  Stream<List<Contacto>> obtenerContactos() {
    return _coleccion.orderBy('categoria').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Contacto.fromFirestore(doc)).toList();
    });
  }

  /// Siembra datos iniciales si la colección está vacía.
  Future<void> sembrarDatosIniciales() async {
    final snapshot = await _coleccion.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final contactos = [
      Contacto(
        id: '',
        nombre: 'Policía Municipal',
        categoria: 'Seguridad',
        telefono: '911',
        horario: '24 horas',
        funciones: 'Seguridad pública, patrullaje, atención a denuncias ciudadanas.',
        direccion: 'Presidencia Municipal',
      ),
      Contacto(
        id: '',
        nombre: 'Guardia Nacional',
        categoria: 'Seguridad',
        telefono: '088',
        horario: '24 horas',
        funciones: 'Seguridad nacional, apoyo en emergencias, vigilancia carretera.',
      ),
      Contacto(
        id: '',
        nombre: 'Cruz Roja',
        categoria: 'Salud',
        telefono: '065',
        horario: '24 horas',
        funciones: 'Atención prehospitalaria, traslado de emergencia, primeros auxilios.',
      ),
      Contacto(
        id: '',
        nombre: 'Hospital General',
        categoria: 'Salud',
        telefono: '800-123-4567',
        horario: '24 horas',
        funciones: 'Atención médica general, urgencias, hospitalización.',
        direccion: 'Blvd. Principal #200',
      ),
      Contacto(
        id: '',
        nombre: 'Bomberos',
        categoria: 'Protección Civil',
        telefono: '068',
        horario: '24 horas',
        funciones: 'Combate de incendios, rescate, atención a fugas de gas.',
      ),
      Contacto(
        id: '',
        nombre: 'Protección Civil Municipal',
        categoria: 'Protección Civil',
        telefono: '800-765-4321',
        horario: 'Lun-Vie 8:00–18:00',
        funciones: 'Prevención de desastres, planes de evacuación, inspección de zonas de riesgo.',
        direccion: 'Palacio Municipal',
      ),
    ];

    final batch = _firestore.batch();
    for (final contacto in contactos) {
      batch.set(_coleccion.doc(), contacto.toMap());
    }
    await batch.commit();
  }
}
