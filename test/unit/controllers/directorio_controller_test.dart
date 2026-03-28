import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alertacan/controllers/directorio_controller.dart';
import 'package:alertacan/models/contacto_model.dart';

// 1. @GenerateMocks va ANTES del import del archivo generado
@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockQueryDocumentSnapshot),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
  MockSpec<WriteBatch>(),
  MockSpec<Query<Map<String, dynamic>>>(as: #MockQuery),
])
// 2. El import del archivo generado va después de la anotación
import 'directorio_controller_test.mocks.dart';

void main() {
  group('Pruebas Unitarias - DirectorioController', () {
    late DirectorioController controller;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();

      when(mockFirestore.collection('directorio')).thenReturn(mockCollection);
      // orderBy devuelve Query, no CollectionReference
      when(mockCollection.orderBy('categoria')).thenReturn(mockCollection);

      controller = DirectorioController(firestore: mockFirestore);
    });

    group('Flujo Normal - Cargar Contactos', () {
      test(
        'Test 10: Obtener lista de contactos ordenada por categoría',
        () async {
          final mockSnapshot = MockQuerySnapshot();
          final mockDocs = [
            _createMockDocument(
              id: '1',
              data: {
                'nombre': 'Policía',
                'telefono': '911',
                'categoria': 'Seguridad',
                'horario': '24 horas',
              },
            ),
            _createMockDocument(
              id: '2',
              data: {
                'nombre': 'Cruz Roja',
                'telefono': '065',
                'categoria': 'Salud',
                'horario': '24 horas',
              },
            ),
          ];

          when(mockSnapshot.docs).thenReturn(mockDocs);
          when(
            mockCollection.snapshots(),
          ).thenAnswer((_) => Stream.value(mockSnapshot));

          final contactos = await controller.obtenerContactos().first;

          expect(contactos.length, equals(2));
          expect(contactos[0].nombre, equals('Policía'));
          expect(contactos[0].categoria, equals('Seguridad'));
          expect(contactos[1].nombre, equals('Cruz Roja'));
        },
      );
    });

    group('Flujo Normal - Sembrar Datos Iniciales', () {
      test('Test 11: Sembrar datos solo si la colección está vacía', () async {
        final mockSnapshot = MockQuerySnapshot();
        when(mockSnapshot.docs).thenReturn([]);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockSnapshot);

        final mockBatch = MockWriteBatch();
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => {});

        await controller.sembrarDatosIniciales();

        verify(mockBatch.commit()).called(1);
      });

      test('Test 12: No sembrar datos si ya existen contactos', () async {
        final mockSnapshot = MockQuerySnapshot();
        final mockDocs = [
          _createMockDocument(id: '1', data: {'nombre': 'Policía'}),
        ];
        when(mockSnapshot.docs).thenReturn(mockDocs);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockSnapshot);

        await controller.sembrarDatosIniciales();

        verifyNever(mockFirestore.batch());
      });
    });
  });
}

MockQueryDocumentSnapshot _createMockDocument({
  required String id,
  required Map<String, dynamic> data,
}) {
  final mockDoc = MockQueryDocumentSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}
