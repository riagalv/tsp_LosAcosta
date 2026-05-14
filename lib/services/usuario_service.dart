import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Servicio que gestiona la identidad del colono en el dispositivo.
/// Genera un ID único en el primer arranque y lo persiste localmente.
/// Cuando se integre Firebase Auth, este servicio se reemplaza con el UID real.
class UsuarioService {
  static const String _keyUserId = 'dispositivo_user_id';

  static String? _userId;

  /// Inicializa el servicio y crea el userId si aún no existe.
  /// Llamar una sola vez en main() antes de runApp.
  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_keyUserId);
    if (stored == null || stored.isEmpty) {
      stored = _generarId();
      await prefs.setString(_keyUserId, stored);
    }
    _userId = stored;
  }

  /// Devuelve el userId del dispositivo actual.
  /// Lanza un error si [inicializar] no fue llamado primero.
  static String get userId {
    assert(_userId != null, 'UsuarioService.inicializar() debe llamarse antes de usar userId');
    return _userId!;
  }

  static String _generarId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final sufijo = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'usr_${timestamp}_$sufijo';
  }
}
