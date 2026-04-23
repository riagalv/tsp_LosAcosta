import 'package:alertacan/models/contacto_model.dart';
import 'package:flutter/material.dart';
import '../controllers/directorio_controller.dart';
import '../widgets/directorio_widgets.dart';

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

  // Lógica de filtrado (podría moverse al controlador si es más compleja)
  List<ContactoModel> _aplicarFiltros(List<ContactoModel> contactos) {
    var resultado = contactos;

    if (_categoriaSeleccionada != null) {
      resultado = resultado
          .where((c) => c.categoria == _categoriaSeleccionada)
          .toList();
    }

    if (_filtro.isNotEmpty) {
      resultado = resultado
          .where((c) => c.nombre.toLowerCase().contains(_filtro))
          .toList();
    }

    return resultado;
  }

  // Obtener categorías únicas
  List<String> _obtenerCategorias(List<ContactoModel> contactos) {
    return contactos.map((c) => c.categoria).toSet().toList()..sort();
  }

  // Agrupar contactos por categoría
  Map<String, List<ContactoModel>> _agruparPorCategoria(
    List<ContactoModel> contactos,
  ) {
    final Map<String, List<ContactoModel>> grupos = {};
    for (final c in contactos) {
      grupos.putIfAbsent(c.categoria, () => []).add(c);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Emergencia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<ContactoModel>>(
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
              BarraBusqueda(controller: _busquedaCtrl, filtro: _filtro),

              // Chips de categorías
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // Chip "Todas"
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
                    // Chips de categorías dinámicas
                    ...categorias.map((cat) {
                      return CategoriaChip(
                        categoria: cat,
                        isSelected: _categoriaSeleccionada == cat,
                        onTap: () {
                          setState(() {
                            _categoriaSeleccionada =
                                _categoriaSeleccionada == cat ? null : cat;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Lista de contactos o mensaje vacío
              Expanded(
                child: contactosFiltrados.isEmpty
                    ? const SinResultadosWidget()
                    : _buildListaContactos(contactosFiltrados),
              ),
            ],
          );
        },
      ),
    );
  }

  // Lista de contactos agrupados visualmente
  Widget _buildListaContactos(List<ContactoModel> contactos) {
    final grupos = _agruparPorCategoria(contactos);
    final categoriasOrdenadas = grupos.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categoriasOrdenadas.length,
      itemBuilder: (context, index) {
        final categoria = categoriasOrdenadas[index];
        final contactosCat = grupos[categoria]!;
        final color = CategoriaConfig.getColor(categoria);
        final icono = CategoriaConfig.getIcono(categoria);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de categoría
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(icono, size: 20, color: color),
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
            ...contactosCat.map(
              (contacto) => ContactoTarjeta(contacto: contacto),
            ),
          ],
        );
      },
    );
  }
}
