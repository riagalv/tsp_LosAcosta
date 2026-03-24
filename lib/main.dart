import 'package:alertacan/views/historial_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/directorio_screen.dart';
import 'views/alerta_confirmacion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaCan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        fontFamily: 'Roboto',
      ),
      home: const MyHomePage(),
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
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    setState(() => _presionando = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (_presionando && mounted) {
        setState(() => _presionando = false);

        if (_nivelSeleccionado < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona un nivel de riesgo primero'),
              backgroundColor: Colors.grey,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertaConfirmacionScreen(
              nivelRiesgo: _niveles[_nivelSeleccionado]['label'] as String,
            ),
          ),
        );
      }
    });
  }

  void _onLongPressEnd() {
    setState(() => _presionando = false);
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
                          onLongPressStart: (_) => _onLongPressStart(),
                          onLongPressEnd: (_) => _onLongPressEnd(),
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
                                        'MANTÉN\nPRESIONADO PARA\nALERTAR',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
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
                                  TextSpan(text: ' y mantén presionado\nel '),
                                  TextSpan(
                                    text: 'botón de pánico',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' por 2 segundos para enviar una\nalerta inmediata.',
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

            // Botón circular: Directorio de Emergencia (esquina inferior izquierda)
            Positioned(
              left: 40,
              bottom: 24,
              child: FloatingActionButton(
                heroTag: 'directorio',
                backgroundColor: Colors.grey.shade300,
                shape: const CircleBorder(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DirectorioScreen()),
                  );
                },
                tooltip: 'Directorio de Emergencia',
                child: Icon(Icons.menu_book, color: Colors.grey.shade800),
              ),
            ),

            // Botón circular: Historial (esquina inferior derecha)
            Positioned(
              right: 40,
              bottom: 24,
              child: FloatingActionButton(
                heroTag: 'historial',
                backgroundColor: Colors.grey.shade300,
                shape: const CircleBorder(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistorialScreen()),
                  );
                },
                tooltip: 'Historial',
                child: Icon(Icons.history, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
