import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'AlertaCan'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // GUARDAR EN FIRESTORE
  Future<void> crearAlerta() async {
    try {
      await FirebaseFirestore.instance.collection('alertas').add({
        'tipo': 'perro agresivo',
        'fecha': Timestamp.now(),
      });

      print("Alerta guardada en Firebase");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alerta creada correctamente")),
      );
    } catch (e) {
      print("Error al guardar: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar en Firebase")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Presiona el botón para crear una alerta',
          style: TextStyle(fontSize: 16),
        ),
      ),

      // BOTON QUE GUARDA EN FIRESTORE
      floatingActionButton: FloatingActionButton(
        onPressed: crearAlerta,
        tooltip: 'Crear alerta',
        child: const Icon(Icons.warning),
      ),
    );
  }
}
