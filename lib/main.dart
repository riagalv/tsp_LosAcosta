import 'package:alertacan/views/historial_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'views/directorio_screen.dart';
import 'views/alerta_confirmacion_screen.dart';
import 'views/login_screen.dart';
import 'views/registrar_punto_seguro_screen.dart';
import 'views/mapa_expandido_screen.dart';
import 'services/onesignal_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _limpiarAlertasAntiguas() async {
  try {
    final haceUnaSemana = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await FirebaseFirestore.instance
        .collection('alertas')
        .where('fecha', isLessThan: Timestamp.fromDate(haceUnaSemana))
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint('Se eliminaron ${snapshot.docs.length} alertas antiguas.');
  } catch (e) {
    debugPrint('Error limpiando alertas antiguas: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OneSignalService.inicializar();

  // Limpiar alertas que tengan más de una semana de antigüedad
  _limpiarAlertasAntiguas();

  final prefs = await SharedPreferences.getInstance();
  final logueado = prefs.getBool('logueado') ?? false;

  runApp(MyApp(logueado: logueado));
}

class MyApp extends StatefulWidget {
  final bool logueado;
  const MyApp({super.key, required this.logueado});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _logueado;

  @override
  void initState() {
    super.initState();
    _logueado = widget.logueado;
  }

  void _onLoginExitoso() {
    setState(() => _logueado = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaCan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        fontFamily: 'Roboto',
      ),
      home: _logueado
          ? const MyHomePage()
          : LoginScreen(onLoginExitoso: _onLoginExitoso),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _nivelSeleccionado = -1; // -1 = ninguno, 0 = bajo, 1 = medio, 2 = alto
  bool _presionando = false;
  late AnimationController _auraController;
  late Animation<double> _auraAnimation;

  final List<Map<String, dynamic>> _niveles = [
    {
      'label': 'BAJO',
      'color': const Color(0xFFF4C542),
      'icon': Icons.warning_rounded,
    },
    {
      'label': 'MEDIO',
      'color': const Color(0xFFF48C42),
      'icon': Icons.groups_rounded,
    },
    {
      'label': 'ALTO',
      'color': const Color(0xFFE84C3D),
      'icon': Icons.local_fire_department_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _auraAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );
    OneSignalService.registrarDispositivo();
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  void _onBotonPanicoTap() async {
    // Breve animación visual al presionar
    setState(() => _presionando = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _presionando = false);

    if (_nivelSeleccionado < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un nivel de riesgo primero'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertaConfirmacionView(
            nivelRiesgo: _niveles[_nivelSeleccionado]['label'] as String,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal scrollable
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Título
                    const Text(
                      'ALERTACAN',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE84C3D),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avistamiento de Perro Agresivo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Subtítulo
                    const Text(
                      'SELECCIONA EL NIVEL DE RIESGO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C2C2C),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botones de nivel de riesgo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final nivel = _niveles[index];
                        final seleccionado = _nivelSeleccionado == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _nivelSeleccionado = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: nivel['color'] as Color,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: seleccionado
                                  ? [
                                      BoxShadow(
                                        color: (nivel['color'] as Color)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                              border: seleccionado
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  nivel['icon'] as IconData,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nivel['label'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    // Botón de pánico con aura parpadeante
                    AnimatedBuilder(
                      animation: _auraAnimation,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: _onBotonPanicoTap,
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Aura exterior (más grande, más transparente)
                                Container(
                                  width: 240 + (_auraAnimation.value * 20),
                                  height: 240 + (_auraAnimation.value * 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE84C3D).withValues(
                                      alpha:
                                          0.08 + (_auraAnimation.value * 0.04),
                                    ),
                                  ),
                                ),

                                // Aura media
                                Container(
                                  width: 210 + (_auraAnimation.value * 10),
                                  height: 210 + (_auraAnimation.value * 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE84C3D).withValues(
                                      alpha:
                                          0.12 + (_auraAnimation.value * 0.06),
                                    ),
                                  ),
                                ),

                                // Aura interior
                                Container(
                                  width: 185 + (_auraAnimation.value * 5),
                                  height: 185 + (_auraAnimation.value * 5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE84C3D).withValues(
                                      alpha:
                                          0.18 + (_auraAnimation.value * 0.06),
                                    ),
                                  ),
                                ),

                                // Botón central
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _presionando ? 150 : 160,
                                  height: _presionando ? 150 : 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE84C3D),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE84C3D,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: _presionando ? 20 : 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'TOCA PARA\nALERTAR',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          height: 1.3,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Texto informativo inferior
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(text: 'Selecciona el '),
                                  TextSpan(
                                    text: 'nivel de riesgo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE84C3D),
                                    ),
                                  ),
                                  TextSpan(text: ' y toca el\n'),
                                  TextSpan(
                                    text: 'botón de pánico',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' para enviar una alerta inmediata.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Navbar flotante (Pill)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.menu_book, 'Directorio', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DirectorioScreen()),
                      );
                    }),
                    _buildNavItem(Icons.verified_user, 'Punto Seguro', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistrarPuntoSeguroScreen()),
                      );
                    }),
                    _buildNavItem(Icons.map_outlined, 'Mapa', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapaExpandidoScreen()),
                      );
                    }),
                    _buildNavItem(Icons.history, 'Historial', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HistorialScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: const Color(0xFF4A5568), size: 28),
          ),
        ),
      ),
    );
  }
}
