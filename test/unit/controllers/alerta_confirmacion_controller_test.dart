import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertacan/controllers/alerta_confirmacion_controller.dart';
import 'package:alertacan/services/ubicacion_service.dart';
import 'package:alertacan/models/alerta_model.dart';

// Generar mocks
@GenerateNiceMocks([
  MockSpec<UbicacionService>(),
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<SharedPreferences>(),
])
import 'alerta_confirmacion_controller_test.mocks.dart';

void main() {
  group('Pruebas Unitarias - AlertaConfirmacionController', () {
    late AlertaConfirmacionController controller;
    late MockUbicacionService mockUbicacionService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockSharedPreferences mockPreferences;

    setUp(() {
      mockUbicacionService = MockUbicacionService();
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockPreferences = MockSharedPreferences();

      // Configurar mocks
      when(mockFirestore.collection('alertas')).thenReturn(mockCollection);
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocument);

      // Inyectar mocks (necesitarías modificar el controller para aceptar dependencias)
    });

    group('Flujo Normal - Enviar Alerta', () {
      test('Test 1: Obtener ubicación y guardar alerta exitosamente', () async {
        // Arrange: Simular ubicación exitosa
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

        when(
          mockUbicacionService.obtenerUbicacionActual(),
        ).thenAnswer((_) async => mockPosition);
        when(
          mockUbicacionService.obtenerTextoUbicacion(any),
        ).thenReturn('19.4326, -99.1332');

        // Simular SharedPreferences
        when(mockPreferences.getString('nombre')).thenReturn('Juan');
        when(mockPreferences.getString('apellido')).thenReturn('Pérez');

        // Act: Crear controller y obtener ubicación
        controller = AlertaConfirmacionController(
          nivelRiesgo: 'ALTO',
          ubicacionService: mockUbicacionService,
          firestore: mockFirestore,
          sharedPreferences: mockPreferences,
        );

        // Llamar al método
        await controller.obtenerUbicacion();

        // Assert: Verificar que se guardó la alerta
        expect(controller.cargando, false);
        expect(controller.posicion, isNotNull);
        verify(mockCollection.add(any)).called(1);
      });

      test(
        'Test 2: Validar que la alerta se guarda con los datos correctos',
        () async {
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

          when(
            mockUbicacionService.obtenerUbicacionActual(),
          ).thenAnswer((_) async => mockPosition);
          when(mockPreferences.getString('nombre')).thenReturn('María');
          when(mockPreferences.getString('apellido')).thenReturn('López');

          Map<String, dynamic>? datosGuardados;
          when(mockCollection.add(any)).thenAnswer((invocation) async {
            datosGuardados = invocation.positionalArguments[0];
            return mockDocument;
          });

          // Act
          controller = AlertaConfirmacionController(
            nivelRiesgo: 'MEDIO',
            ubicacionService: mockUbicacionService,
            firestore: mockFirestore,
            sharedPreferences: mockPreferences,
          );
          await controller.obtenerUbicacion();

          // Assert
          expect(datosGuardados, isNotNull);
          expect(datosGuardados!['riesgo'], equals('MEDIO'));
          expect(datosGuardados!['estado'], equals('activa'));
          expect(datosGuardados!['emisor'], equals('María López'));
          expect(datosGuardados!['latitud'], equals(19.4326));
          expect(datosGuardados!['longitud'], equals(-99.1332));
        },
      );
    });

    group('Flujos Alternativos - Errores de Ubicación', () {
      test('Test 3: Servicios de ubicación deshabilitados', () async {
        // Arrange
        when(
          mockUbicacionService.obtenerUbicacionActual(),
        ).thenThrow(Exception('Servicios de ubicación deshabilitados'));

        // Act
        controller = AlertaConfirmacionController(
          nivelRiesgo: 'ALTO',
          ubicacionService: mockUbicacionService,
          firestore: mockFirestore,
          sharedPreferences: mockPreferences,
        );
        await controller.obtenerUbicacion();

        // Assert
        expect(controller.cargando, false);
        expect(controller.ubicacionTexto, contains('deshabilitados'));
        verifyNever(mockCollection.add(any));
      });

      test('Test 4: Permiso de ubicación denegado', () async {
        // Arrange
        when(
          mockUbicacionService.obtenerUbicacionActual(),
        ).thenThrow(Exception('Permiso de ubicación denegado'));

        // Act
        controller = AlertaConfirmacionController(
          nivelRiesgo: 'ALTO',
          ubicacionService: mockUbicacionService,
          firestore: mockFirestore,
          sharedPreferences: mockPreferences,
        );
        await controller.obtenerUbicacion();

        // Assert
        expect(controller.cargando, false);
        expect(controller.ubicacionTexto, contains('denegado'));
        verifyNever(mockCollection.add(any));
      });

      test('Test 5: Error de red al guardar alerta', () async {
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

        when(
          mockUbicacionService.obtenerUbicacionActual(),
        ).thenAnswer((_) async => mockPosition);
        when(mockCollection.add(any)).thenThrow(Exception('Error de red'));

        when(mockPreferences.getString('nombre')).thenReturn('Juan');
        when(mockPreferences.getString('apellido')).thenReturn('Pérez');

        // Act & Assert
        controller = AlertaConfirmacionController(
          nivelRiesgo: 'ALTO',
          ubicacionService: mockUbicacionService,
          firestore: mockFirestore,
          sharedPreferences: mockPreferences,
        );

        // Act
        await controller.obtenerUbicacion();

        // Assert
        expect(controller.cargando, false);
        expect(controller.ubicacionTexto, contains('Error de red'));
      });
    });

    group('Flujo Alternativo - Usuario Anónimo', () {
      test('Test 6: Usuario sin nombre registrado', () async {
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

        when(
          mockUbicacionService.obtenerUbicacionActual(),
        ).thenAnswer((_) async => mockPosition);
        when(mockPreferences.getString('nombre')).thenReturn(null);
        when(mockPreferences.getString('apellido')).thenReturn(null);

        Map<String, dynamic>? datosGuardados;
        when(mockCollection.add(any)).thenAnswer((invocation) async {
          datosGuardados = invocation.positionalArguments[0];
          return mockDocument;
        });

        // Act
        controller = AlertaConfirmacionController(
          nivelRiesgo: 'BAJO',
          ubicacionService: mockUbicacionService,
          firestore: mockFirestore,
          sharedPreferences: mockPreferences,
        );
        await controller.obtenerUbicacion();

        // Assert
        expect(datosGuardados!['emisor'], equals('Anónimo'));
      });
    });
  });
}
