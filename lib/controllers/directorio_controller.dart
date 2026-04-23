import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contacto_model.dart';

class DirectorioController {
  final CollectionReference _coleccion =
      FirebaseFirestore.instance.collection('directorio');

  /// Obtiene todos los contactos en tiempo real.
  Stream<List<ContactoModel>> obtenerContactos() {
    return _coleccion.orderBy('categoria').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ContactoModel.fromFirestore(doc)).toList();
    });
  }

  /// Siembra datos iniciales si la colección está vacía.
  Future<void> sembrarDatosIniciales() async {
    final snapshot = await _coleccion.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final contactos = [
      ContactoModel(
        id: '',
        nombre: 'Policía Municipal',
        categoria: 'Seguridad',
        telefono: '911',
        horario: '24 horas',
        funciones: 'Seguridad pública, patrullaje, atención a denuncias ciudadanas.',
        direccion: 'Presidencia Municipal',
      ),
      ContactoModel(
        id: '',
        nombre: 'Guardia Nacional',
        categoria: 'Seguridad',
        telefono: '088',
        horario: '24 horas',
        funciones: 'Seguridad nacional, apoyo en emergencias, vigilancia carretera.',
      ),
      ContactoModel(
        id: '',
        nombre: 'Cruz Roja',
        categoria: 'Salud',
        telefono: '065',
        horario: '24 horas',
        funciones: 'Atención prehospitalaria, traslado de emergencia, primeros auxilios.',
      ),
      ContactoModel(
        id: '',
        nombre: 'Hospital General',
        categoria: 'Salud',
        telefono: '800-123-4567',
        horario: '24 horas',
        funciones: 'Atención médica general, urgencias, hospitalización.',
        direccion: 'Blvd. Principal #200',
      ),
      ContactoModel(
        id: '',
        nombre: 'Bomberos',
        categoria: 'Protección Civil',
        telefono: '068',
        horario: '24 horas',
        funciones: 'Combate de incendios, rescate, atención a fugas de gas.',
      ),
      ContactoModel(
        id: '',
        nombre: 'Protección Civil Municipal',
        categoria: 'Protección Civil',
        telefono: '800-765-4321',
        horario: 'Lun-Vie 8:00–18:00',
        funciones: 'Prevención de desastres, planes de evacuación, inspección de zonas de riesgo.',
        direccion: 'Palacio Municipal',
      ),
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final contacto in contactos) {
      batch.set(_coleccion.doc(), contacto.toMap());
    }
    await batch.commit();
  }
}
