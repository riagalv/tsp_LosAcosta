import 'package:flutter_test/flutter_test.dart';
import 'package:alertacan/services/geocoding_service.dart';

void main() {
  group('Pruebas Unitarias - GeocodingService', () {
    group('Formateo de direcciones', () {
      test(
        'Test 18: obtenerDireccionDesdeCoordenadas - formato correcto',
        () async {
          // Nota: Este test requiere conexión a internet real
          // o puedes mockear el paquete geocoding

          final resultado =
              await GeocodingService.obtenerDireccionDesdeCoordenadas(
                19.4326,
                -99.1332,
              );

          // Verificar que devuelve un string no vacío
          expect(resultado, isNotEmpty);
        },
      );

      test(
        'Test 19: Fallback cuando hay error - mostrar coordenadas',
        () async {
          // Simular error (coordenadas inválidas)
          final resultado =
              await GeocodingService.obtenerDireccionDesdeCoordenadas(
                999.0,
                999.0,
              );

          // Debe devolver coordenadas como fallback
          expect(resultado, contains('999.0000'));
        },
      );
    });
  });
}
