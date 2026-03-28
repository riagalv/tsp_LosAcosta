import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alertacan/services/ubicacion_service.dart';

void main() {
  group('Pruebas Unitarias - UbicacionService', () {
    late UbicacionService service;

    setUp(() {
      service = UbicacionService();
    });

    group('Flujo Normal', () {
      test('Test 16: obtenerTextoUbicacion - formato correcto', () {
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

        final resultado = service.obtenerTextoUbicacion(mockPosition);

        expect(resultado, equals('19.4326, -99.1332'));
      });

      test('Test 17: obtenerTextoUbicacion - redondeo correcto', () {
        final mockPosition = Position(
          latitude: 19.4326789,
          longitude: -99.1332456,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        final resultado = service.obtenerTextoUbicacion(mockPosition);

        expect(resultado, equals('19.4327, -99.1332'));
      });
    });
  });
}
