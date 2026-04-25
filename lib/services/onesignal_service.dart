import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OneSignalService {
  static const String _appId = '4f924a27-f277-4028-b0af-b9cb284ddcf1';
  static const String _restApiKey =
      'os_v2_app_j6jeuj7so5acrmfpxhfsqto46hpv6akuq5iefrei6quw2ouvbqffvnnpq6v2twcmziquvgh7ejoiygq557ez7bbnpuu6k75hcoyf2ci';
  static const double _radioKm = 0.5;
  final FirebaseFirestore _firestore;

  OneSignalService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static Future<void> inicializar() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(false);
  }

  static Future<void> registrarDispositivo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('deviceId');
      if (deviceId == null) {
        deviceId =
            'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        await prefs.setString('deviceId', deviceId);
      }
      await Future.delayed(const Duration(seconds: 2));
      final oneSignalId = OneSignal.User.pushSubscription.id;
      if (oneSignalId == null || oneSignalId.isEmpty) return;
      final nombre = prefs.getString('nombre') ?? '';
      final apellido = prefs.getString('apellido') ?? '';
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(deviceId)
          .set({
            'oneSignalId': oneSignalId,
            'nombre': nombre,
            'apellido': apellido,
            'ultimaConexion': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error registrando dispositivo: $e');
    }
  }

  static Future<void> actualizarUbicacion(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId');
      if (deviceId == null) return;
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(deviceId)
          .update({
            'ubicacion': {'latitud': lat, 'longitud': lon},
            'ultimaUbicacion': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error actualizando ubicación: $e');
    }
  }

  Future<int> notificarUsuariosCercanos({
    required double latitudAlerta,
    required double longitudAlerta,
    required String riesgo,
    required String direccion,
    required String emisor,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('oneSignalId', isNotEqualTo: null)
          .get();
      if (snapshot.docs.isEmpty) return 0;
      final List<String> idsCercanos = [];
      final String? miOneSignalId = OneSignal.User.pushSubscription.id;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ubicacion = data['ubicacion'] as Map<String, dynamic>?;
        final ultimaUbicacion = data['ultimaUbicacion'] as Timestamp?;
        final oneSignalId = data['oneSignalId'] as String?;
        if (ubicacion == null || oneSignalId == null) continue;
        if (oneSignalId == miOneSignalId) continue; // No notificar al emisor
        
        if (ultimaUbicacion != null) {
          if (DateTime.now().difference(ultimaUbicacion.toDate()).inHours > 24) {
            continue;
          }
        }
        final dist = _calcularDistanciaKm(
          latitudAlerta,
          longitudAlerta,
          (ubicacion['latitud'] as num).toDouble(),
          (ubicacion['longitud'] as num).toDouble(),
        );
        if (dist <= _radioKm) idsCercanos.add(oneSignalId);
      }
      if (idsCercanos.isEmpty) return 0;
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_player_ids': idsCercanos,
          'headings': {
            'en': '🚨 ¡ALERTA CERCANA!',
            'es': '🚨 ¡ALERTA CERCANA!',
          },
          'contents': {
            'en': '$riesgo: Perro agresivo reportado cerca de $direccion',
            'es': '$riesgo: Perro agresivo reportado cerca de $direccion',
          },
          'data': {
            'latitud': latitudAlerta.toString(),
            'longitud': longitudAlerta.toString(),
            'riesgo': riesgo,
            'direccion': direccion,
            'emisor': emisor,
          },
          'priority': 10,
        }),
      );
      return idsCercanos.length;
    } catch (e) {
      debugPrint('Error notificando: $e');
      return 0;
    }
  }

  static double _calcularDistanciaKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
