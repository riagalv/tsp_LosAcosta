import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/catalogo_perros_controller.dart';

/// Vista del CU-11: Documentar perro callejero
class DocumentarPerroScreen extends StatefulWidget {
  const DocumentarPerroScreen({super.key});

  @override
  State<DocumentarPerroScreen> createState() => _DocumentarPerroScreenState();
}

class _DocumentarPerroScreenState extends State<DocumentarPerroScreen> {
  final _controller = CatalogoPerrosController();
  final _zonaController = TextEditingController();
  final _observacionesController = TextEditingController();

  File? _fotoSeleccionada;
  String _tamanioSeleccionado = '';
  String _colorSeleccionado = '';
  bool _verificandoMunicipio = true;
  bool _dentroDelMunicipio = false;
  bool _guardando = false;

  static const _coloresDisponibles = [
    'Negro',
    'Blanco',
    'Café',
    'Gris',
    'Amarillo',
    'Manchado',
  ];

  @override
  void initState() {
    super.initState();
    _verificarMunicipio();
  }

  @override
  void dispose() {
    _zonaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // ── Paso 2 del flujo: Verificar municipio ──────────────────────────────
  Future<void> _verificarMunicipio() async {
    final resultado = await _controller.verificarMunicipio();
    if (!mounted) return;
    if (!resultado) {
      // El flujo no puede continuar (paso 2, excepción)
      _mostrarDialogoFueraDeMunicipio();
    }
    setState(() {
      _dentroDelMunicipio = resultado;
      _verificandoMunicipio = false;
    });
  }

  void _mostrarDialogoFueraDeMunicipio() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, color: Colors.orange.shade700, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fuera del municipio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Debes estar dentro del municipio de Zacatecas para documentar un perro callejero.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // cierra diálogo
                  Navigator.pop(context); // regresa al menú
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84C3D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Selección de fotografía (obligatoria) ──────────────────────────────
  Future<void> _seleccionarFoto(ImageSource fuente) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: fuente, imageQuality: 70);
    if (picked != null) {
      setState(() => _fotoSeleccionada = File(picked.path));
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'AGREGAR FOTOGRAFÍA',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 20),
              _buildOpcionFoto(Icons.camera_alt, 'Tomar foto', () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.camera);
              }),
              const SizedBox(height: 12),
              _buildOpcionFoto(Icons.photo_library, 'Elegir de galería', () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.gallery);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionFoto(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE84C3D), size: 24),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Paso 5-7: Confirmar y guardar perfil ────────────────────────────────
  void _onGuardarPerfil() {
    // Paso 6: Validar campos obligatorios (FE1)
    if (_fotoSeleccionada == null) {
      _mostrarError('La fotografía es obligatoria para documentar un perro.');
      return;
    }
    if (_tamanioSeleccionado.isEmpty) {
      _mostrarError('Selecciona el tamaño aproximado del perro.');
      return;
    }
    if (_colorSeleccionado.isEmpty) {
      _mostrarError('Selecciona el color predominante del perro.');
      return;
    }
    if (_zonaController.text.trim().isEmpty) {
      _mostrarError('Indica la zona habitual de avistamiento.');
      return;
    }

    // Paso 5: Cuadro de confirmación antes de guardar (FA1 si cancela)
    _mostrarDialogoConfirmacion();
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.pets, color: Colors.orange.shade700, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Guardar perfil?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'El perfil quedará disponible en el catálogo comunitario para consulta y votación de todos los colonos.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _guardarPerfil(); // Paso 7
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84C3D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              // FA1: cancelar y descartar
              onPressed: () {
                Navigator.pop(context); // cierra diálogo
                Navigator.pop(context); // regresa al catálogo
              },
              child: Text('CANCELAR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPerfil() async {
    setState(() => _guardando = true);
    try {
      await _controller.documentarPerro(
        foto: _fotoSeleccionada!,
        tamanio: _tamanioSeleccionado,
        color: _colorSeleccionado,
        zona: _zonaController.text.trim(),
        observaciones: _observacionesController.text.trim(),
      );

      if (!mounted) return;
      // Paso 8: Confirmación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado exitosamente en el catálogo comunitario.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Regresa al catálogo
    } catch (e) {
      // FE2: Fallo de conexión
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('No se pudo guardar el perfil. Verifica tu conexión e intenta nuevamente.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          // FA1: regresar descarta los datos
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DOCUMENTAR PERRO',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
        ),
      ),
      body: _verificandoMunicipio
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE84C3D)))
          : !_dentroDelMunicipio
              ? const SizedBox.shrink() // El diálogo ya se mostró
              : _buildFormulario(),
      // Paso 5: Botón de guardar
      bottomNavigationBar: (!_verificandoMunicipio && _dentroDelMunicipio)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _onGuardarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE84C3D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'GUARDAR PERFIL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documenta al perro',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1C2833)),
          ),
          const SizedBox(height: 8),
          Text(
            'El perfil quedará disponible en el catálogo comunitario para que otros colonos puedan reconocerlo.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),

          // ── FOTOGRAFÍA (obligatoria) ──
          _buildSectionTitle('FOTOGRAFÍA DEL PERRO *'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _mostrarOpcionesFoto,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _fotoSeleccionada == null ? Colors.grey.shade300 : const Color(0xFFE84C3D),
                  width: _fotoSeleccionada == null ? 1.5 : 2,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: _fotoSeleccionada != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.black,
                          child: Image.file(_fotoSeleccionada!, fit: BoxFit.contain),
                        ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: GestureDetector(
                            onTap: _mostrarOpcionesFoto,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('CAMBIAR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Toca para agregar fotografía', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('(Obligatoria)', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // ── TAMAÑO APROXIMADO ──
          _buildSectionTitle('TAMAÑO APROXIMADO *'),
          const SizedBox(height: 12),
          Row(
            children: ['Pequeño', 'Mediano', 'Grande'].map((t) {
              final sel = _tamanioSeleccionado == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tamanioSeleccionado = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE84C3D) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? const Color(0xFFE84C3D) : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: const Color(0xFFE84C3D).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Text(
                      t,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // ── COLOR PREDOMINANTE ──
          _buildSectionTitle('COLOR PREDOMINANTE *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _coloresDisponibles.map((c) {
              final sel = _colorSeleccionado == c;
              return GestureDetector(
                onTap: () => setState(() => _colorSeleccionado = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE84C3D) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: sel ? const Color(0xFFE84C3D) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // ── ZONA HABITUAL ──
          _buildSectionTitle('ZONA HABITUAL DE AVISTAMIENTO *'),
          const SizedBox(height: 8),
          TextField(
            controller: _zonaController,
            decoration: InputDecoration(
              hintText: 'Ej. Calle 5 de Mayo, Colonia Centro...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE84C3D), width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 32),

          // ── OBSERVACIONES (opcionales) ──
          _buildSectionTitle('OBSERVACIONES ADICIONALES'),
          Text('Opcional', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          TextField(
            controller: _observacionesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Comportamiento observado, cicatrices, collar, etc.',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE84C3D), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4A3428),
        letterSpacing: 1.2,
      ),
    );
  }
}
