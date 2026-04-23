import 'dart:convert';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Para notificaciones en primer plano
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback para cuando se recibe una notificación y la app está en primer plano
  Function(Map<String, dynamic>)? onMessageReceived;

  // Callback para cuando se abre la app desde una notificación
  Function(Map<String, dynamic>)? onNotificationOpened;

  // Inicializar todo el servicio
  Future<void> inicializar() async {
    // 1. Solicitar permisos
    await _solicitarPermisos();

    // 2. Configurar canal para Android
    await _configurarCanalAndroid();

    // 3. Inicializar notificaciones locales
    await _inicializarLocalNotifications();

    // 4. Obtener y guardar token FCM
    await _obtenerYGuardarToken();

    // 5. Escuchar notificaciones
    _escucharNotificaciones();
  }

  // Solicitar permisos al usuario
  Future<void> _solicitarPermisos() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // El usuario negó los permisos
      print('Permisos de notificación denegados');
    }
  }

  // Configurar canal para Android (obligatorio para Android 8+)
  Future<void> _configurarCanalAndroid() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alertas_canal', // ID del canal
      'Alertas de Perros', // Nombre visible
      description: 'Notificaciones de avistamientos de perros agresivos',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Inicializar notificaciones locales (para primer plano)
  Future<void> _inicializarLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Cuando el usuario toca la notificación en primer plano
        if (response.payload != null && onNotificationOpened != null) {
          onNotificationOpened!(jsonDecode(response.payload!));
        }
      },
    );
  }

  // Obtener el token FCM del dispositivo
  Future<String?> _obtenerYGuardarToken() async {
    try {
      String? token = await _fcm.getToken();

      if (token != null) {
        print('Token FCM: $token');

        // Guardar en SharedPreferences el teléfono del usuario
        final prefs = await SharedPreferences.getInstance();
        final telefono = prefs.getString('telefono') ?? '';

        if (telefono.isNotEmpty) {
          // Guardar token en Firestore asociado al teléfono
          await _firestore.collection('usuarios').doc(telefono).set({
            'tokenFCM': token,
            'ultimaActualizacion': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        return token;
      }
    } catch (e) {
      print('Error obteniendo token: $e');
    }
    return null;
  }

  // Escuchar diferentes tipos de notificaciones
  void _escucharNotificaciones() {
    // 1. Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación en primer plano: ${message.notification?.title}');

      // Mostrar notificación local
      _mostrarNotificacionLocal(message);

      // Ejecutar callback si existe
      if (onMessageReceived != null) {
        onMessageReceived!(message.data);
      }
    });

    // 2. Cuando la app está en segundo plano y el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación: ${message.data}');

      if (onNotificationOpened != null) {
        onNotificationOpened!(message.data);
      }
    });

    // 3. Cuando la app estaba completamente cerrada y se abre desde notificación
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && onNotificationOpened != null) {
        onNotificationOpened!(message.data);
      }
    });

    // 4. Escuchar cuando el token se actualiza
    _fcm.onTokenRefresh.listen((nuevoToken) async {
      print('Token actualizado: $nuevoToken');
      final prefs = await SharedPreferences.getInstance();
      final telefono = prefs.getString('telefono') ?? '';

      if (telefono.isNotEmpty) {
        await _firestore.collection('usuarios').doc(telefono).set({
          'tokenFCM': nuevoToken,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  // Mostrar notificación local cuando la app está en primer plano
  void _mostrarNotificacionLocal(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alertas_canal',
            'Alertas de Perros',
            channelDescription: 'Notificaciones de avistamientos',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon,
            color: const Color(0xFFE84C3D),
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // Actualizar ubicación del usuario periódicamente (para saber si está cerca)
  Future<void> actualizarUbicacionUsuario({
    required double latitud,
    required double longitud,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final telefono = prefs.getString('telefono') ?? '';

    if (telefono.isNotEmpty) {
      await _firestore.collection('usuarios').doc(telefono).set({
        'ubicacion': {'latitud': latitud, 'longitud': longitud},
        'ultimaUbicacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Eliminar token al cerrar sesión
  Future<void> eliminarToken() async {
    final prefs = await SharedPreferences.getInstance();
    final telefono = prefs.getString('telefono') ?? '';

    if (telefono.isNotEmpty) {
      await _firestore.collection('usuarios').doc(telefono).update({
        'tokenFCM': FieldValue.delete(),
      });
    }
  }
}
