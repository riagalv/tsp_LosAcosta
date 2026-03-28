import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:alertacan/services/ubicacion_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:alertacan/controllers/mapa_controller.dart';
import 'package:alertacan/models/alerta_model.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockQueryDocumentSnapshot),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
  MockSpec<UbicacionService>(),
])
import 'mapa_controller_test.mocks.dart';

void main() {
  group('Pruebas Unitarias - MapaController', () {
    late MapaController controller;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockUbicacionService mockUbicacionService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockUbicacionService = MockUbicacionService();

      when(mockFirestore.collection('alertas')).thenReturn(mockCollection);

      controller = MapaController(
        firestore: mockFirestore,
        ubicacionService: mockUbicacionService,
      );
    });

    group('Flujo Normal - Cargar Alertas en Mapa', () {
      test('Test 10: Cargar alertas y crear marcadores', () async {
        // Arrange
        final mockSnapshot = MockQuerySnapshot();
        final mockDocs = [
          _createMockDocument(
            id: '1',
            data: {
              'latitud': 19.4326,
              'longitud': -99.1332,
              'direccion': 'Av. Insurgentes 123',
              'riesgo': 'ALTO',
              'estado': 'activa',
              'emisor': 'Juan Pérez',
              'fecha': Timestamp.now(),
            },
          ),
          _createMockDocument(
            id: '2',
            data: {
              'latitud': 19.4400,
              'longitud': -99.1400,
              'direccion': 'Parque México',
              'riesgo': 'MEDIO',
              'estado': 'activa',
              'emisor': 'María López',
              'fecha': Timestamp.now(),
            },
          ),
        ];

        when(mockSnapshot.docs).thenReturn(mockDocs);
        when(
          mockCollection.snapshots(),
        ).thenAnswer((_) => Stream.value(mockSnapshot));

        // Act
        controller.cargarAlertas();

        // Esperar a que se procese el stream
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(controller.markers.length, equals(2));
      });

      test('Test 11: Filtrar alertas sin coordenadas válidas', () async {
        // Arrange
        final mockSnapshot = MockQuerySnapshot();
        final mockDocs = [
          _createMockDocument(
            id: '1',
            data: {
              'latitud': 0.0, // Coordenadas inválidas
              'longitud': 0.0,
              'direccion': 'Ubicación desconocida',
              'riesgo': 'ALTO',
              'estado': 'activa',
              'emisor': 'Juan Pérez',
              'fecha': Timestamp.now(),
            },
          ),
          _createMockDocument(
            id: '2',
            data: {
              'latitud': 19.4400,
              'longitud': -99.1400,
              'direccion': 'Parque México',
              'riesgo': 'MEDIO',
              'estado': 'activa',
              'emisor': 'María López',
              'fecha': Timestamp.now(),
            },
          ),
        ];

        when(mockSnapshot.docs).thenReturn(mockDocs);
        when(
          mockCollection.snapshots(),
        ).thenAnswer((_) => Stream.value(mockSnapshot));

        // Act
        controller.cargarAlertas();
        await Future.delayed(Duration(milliseconds: 100));

        // Assert: Solo debe crear marcador para la alerta con coordenadas válidas
        expect(controller.markers.length, equals(1));
      });
    });

    group('Flujo Alternativo - Ubicación GPS', () {
      test('Test 12: Obtener ubicación actual exitosamente', () async {
        // Arrange
        final mockPosition = Position(
          latitude: 19.4326,
          longitude: -99.1332,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        when(mockUbicacionService.obtenerUbicacionActual())
            .thenAnswer((_) async => mockPosition);

        // Act
        await controller.obtenerUbicacionActual();

        // Assert
        expect(controller.gpsActivo, true);
        expect(controller.miPosicion, isNotNull);
      });

      test('Test 13: GPS desactivado - manejar error', () async {
        // Arrange: Simular GPS desactivado
        when(mockUbicacionService.obtenerUbicacionActual())
            .thenThrow(Exception('Servicios de ubicación deshabilitados'));

        // Act
        await controller.obtenerUbicacionActual();

        // Assert
        expect(controller.gpsActivo, false);
      });
    });

    group('Funciones auxiliares', () {
      test('Test 14: getEtiquetaRiesgo - formato correcto', () {
        expect(controller.getEtiquetaRiesgo('ALTO'), equals('Rojo - Alto'));
        expect(
          controller.getEtiquetaRiesgo('MEDIO'),
          equals('Naranja - Medio'),
        );
        expect(controller.getEtiquetaRiesgo('BAJO'), equals('Amarillo - Bajo'));
      });

      test('Test 15: getColorPorRiesgo - colores correctos', () {
        expect(
          controller.getColorPorRiesgo('ALTO'),
          equals(const Color(0xFFE84C3D)),
        );
        expect(
          controller.getColorPorRiesgo('MEDIO'),
          equals(const Color(0xFFF48C42)),
        );
        expect(
          controller.getColorPorRiesgo('BAJO'),
          equals(const Color(0xFFF4C542)),
        );
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
