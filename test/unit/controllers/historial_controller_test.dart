import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alertacan/controllers/historial_controller.dart';
import 'package:alertacan/models/alerta_model.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockQueryDocumentSnapshot),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
])
import 'historial_controller_test.mocks.dart';

void main() {
  group('Pruebas Unitarias - HistorialController', () {
    late HistorialController controller;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();

      when(mockFirestore.collection('alertas')).thenReturn(mockCollection);
      when(
        mockCollection.orderBy('fecha', descending: true),
      ).thenReturn(mockCollection);

      controller = HistorialController(firestore: mockFirestore);
    });

    group('Flujo Normal - Cargar Historial', () {
      test('Test 7: Obtener lista de alertas del usuario', () async {
        // Arrange: Simular datos de Firestore
        final mockSnapshot = MockQuerySnapshot();
        final mockDocs = [
          _createMockDocument(
            id: '1',
            data: {
              'direccion': 'Av. Insurgentes 123',
              'riesgo': 'ALTO',
              'estado': 'activa',
              'emisor': 'Juan Pérez',
              'latitud': 19.4326,
              'longitud': -99.1332,
              'fecha': Timestamp.now(),
            },
          ),
          _createMockDocument(
            id: '2',
            data: {
              'direccion': 'Parque México',
              'riesgo': 'MEDIO',
              'estado': 'activa',
              'emisor': 'María López',
              'latitud': 19.4400,
              'longitud': -99.1400,
              'fecha': Timestamp.now(),
            },
          ),
        ];

        when(mockSnapshot.docs).thenReturn(mockDocs);
        when(
          mockCollection.snapshots(),
        ).thenAnswer((_) => Stream.value(mockSnapshot));

        // Act
        final alertas = await controller.obtenerAlertas().first;

        // Assert
        expect(alertas.length, equals(2));
        expect(alertas[0].direccion, equals('Av. Insurgentes 123'));
        expect(alertas[0].riesgo, equals('ALTO'));
        expect(alertas[1].direccion, equals('Parque México'));
      });

      test(
        'Test 8: Historial vacío - mostrar mensaje sin resultados',
        () async {
          // Arrange
          final mockSnapshot = MockQuerySnapshot();
          when(mockSnapshot.docs).thenReturn([]);
          when(
            mockCollection.snapshots(),
          ).thenAnswer((_) => Stream.value(mockSnapshot));

          // Act
          final alertas = await controller.obtenerAlertas().first;

          // Assert
          expect(alertas, isEmpty);
        },
      );
    });

    group('Flujo Alternativo - Errores', () {
      test('Test 9: Error de conexión a Firestore', () async {
        // Arrange
        when(
          mockCollection.snapshots(),
        ).thenAnswer((_) => Stream.error(Exception('Error de red')));

        // Act & Assert
        expect(
          () async => await controller.obtenerAlertas().first,
          throwsException,
        );
      });
    });
  });
}

// Helper para crear mocks de DocumentSnapshot
MockQueryDocumentSnapshot _createMockDocument({
  required String id,
  required Map<String, dynamic> data,
}) {
  final mockDoc = MockQueryDocumentSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}
