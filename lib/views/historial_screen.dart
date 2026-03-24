import 'package:flutter/material.dart';
import '../controllers/historial_controller.dart';
import '../models/alerta_model.dart';

class HistorialScreen extends StatelessWidget {
  final HistorialController controller = HistorialController();

  HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Historial")),

      body: StreamBuilder<List<Alerta>>(
        stream: controller.obtenerAlertas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertas = snapshot.data!;

          if (alertas.isEmpty) {
            return const Center(child: Text("No hay registros todavía"));
          }

          return ListView.builder(
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final alerta = alertas[index];
              final fecha = alerta.fecha.toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(alerta.direccion),
                  subtitle: Text("${fecha.day}/${fecha.month}/${fecha.year}"),
                  trailing: Text(alerta.riesgo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
