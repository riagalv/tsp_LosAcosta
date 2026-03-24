import 'package:flutter/material.dart';
import '../models/contacto_model.dart';
import '../controllers/directorio_controller.dart';
import 'ficha_tecnica_dialog.dart';

class DirectorioScreen extends StatefulWidget {
  const DirectorioScreen({super.key});

  @override
  State<DirectorioScreen> createState() => _DirectorioScreenState();
}

class _DirectorioScreenState extends State<DirectorioScreen> {
  final DirectorioController _controller = DirectorioController();
  final TextEditingController _busquedaCtrl = TextEditingController();

  String _filtro = '';
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _controller.sembrarDatosIniciales();
    _busquedaCtrl.addListener(() {
      setState(() => _filtro = _busquedaCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Seguridad':
        return Icons.local_police;
      case 'Salud':
        return Icons.local_hospital;
      case 'Protección Civil':
        return Icons.fire_truck;
      default:
        return Icons.info;
    }
  }

  Color _colorCategoria(String categoria) {
    switch (categoria) {
      case 'Seguridad':
        return Colors.blue.shade700;
      case 'Salud':
        return Colors.red.shade600;
      case 'Protección Civil':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  List<Contacto> _aplicarFiltros(List<Contacto> contactos) {
    var resultado = contactos;

    // Filtrar por categoría seleccionada
    if (_categoriaSeleccionada != null) {
      resultado =
          resultado.where((c) => c.categoria == _categoriaSeleccionada).toList();
    }

    // Filtrar por texto de búsqueda
    if (_filtro.isNotEmpty) {
      resultado = resultado
          .where((c) => c.nombre.toLowerCase().contains(_filtro))
          .toList();
    }

    return resultado;
  }

  /// Obtiene las categorías únicas de la lista.
  List<String> _obtenerCategorias(List<Contacto> contactos) {
    return contactos.map((c) => c.categoria).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Emergencia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<Contacto>>(
        stream: _controller.obtenerContactos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar contactos: ${snapshot.error}'),
            );
          }

          final todosContactos = snapshot.data ?? [];
          final categorias = _obtenerCategorias(todosContactos);
          final contactosFiltrados = _aplicarFiltros(todosContactos);

          return Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _busquedaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filtro.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _busquedaCtrl.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),

              // Chips de categorías
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: _categoriaSeleccionada == null,
                        onSelected: (_) {
                          setState(() => _categoriaSeleccionada = null);
                        },
                      ),
                    ),
                    ...categorias.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          avatar: Icon(
                            _iconoCategoria(cat),
                            size: 18,
                            color: _categoriaSeleccionada == cat
                                ? Colors.white
                                : _colorCategoria(cat),
                          ),
                          label: Text(cat),
                          selected: _categoriaSeleccionada == cat,
                          selectedColor: _colorCategoria(cat),
                          labelStyle: TextStyle(
                            color: _categoriaSeleccionada == cat
                                ? Colors.white
                                : null,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _categoriaSeleccionada =
                                  _categoriaSeleccionada == cat ? null : cat;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Lista de contactos o mensaje vacío
              Expanded(
                child: contactosFiltrados.isEmpty
                    ? _buildSinResultados()
                    : _buildListaContactos(contactosFiltrados),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Mensaje cuando no hay coincidencias (E1).
  Widget _buildSinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Sin coincidencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró ninguna institución.\nEn caso de emergencia, llama al 911.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Emergencias: 911',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de contactos agrupados visualmente.
  Widget _buildListaContactos(List<Contacto> contactos) {
    // Agrupar por categoría
    final Map<String, List<Contacto>> grupos = {};
    for (final c in contactos) {
      grupos.putIfAbsent(c.categoria, () => []).add(c);
    }

    final categoriasOrdenadas = grupos.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categoriasOrdenadas.length,
      itemBuilder: (context, index) {
        final categoria = categoriasOrdenadas[index];
        final contactosCat = grupos[categoria]!;
        final color = _colorCategoria(categoria);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de categoría
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(_iconoCategoria(categoria), size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    categoria,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Tarjetas de contactos
            ...contactosCat.map((contacto) {
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_iconoCategoria(categoria), color: color, size: 22),
                  ),
                  title: Text(
                    contacto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    contacto.telefono,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => FichaTecnicaDialog.mostrar(context, contacto),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
