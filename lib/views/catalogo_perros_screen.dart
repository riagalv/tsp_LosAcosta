import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/catalogo_perros_controller.dart';
import '../models/perro_model.dart';
import 'documentar_perro_screen.dart';

/// Vista del CU-12: Consultar catálogo de perros documentados
class CatalogoPerrosScreen extends StatefulWidget {
  const CatalogoPerrosScreen({super.key});

  @override
  State<CatalogoPerrosScreen> createState() => _CatalogoPerrosScreenState();
}

class _CatalogoPerrosScreenState extends State<CatalogoPerrosScreen> {
  final _controller = CatalogoPerrosController();

  List<PerroModel> _perros = [];
  bool _cargando = true;
  bool _sinResultados = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  // ── Paso 2-3: Verificar existencia y cargar catálogo ─────────────────
  Future<void> _cargarCatalogo() async {
    setState(() {
      _cargando = true;
      _sinResultados = false;
    });
    try {
      final lista = await _controller.obtenerCatalogo();
      if (!mounted) return;
      setState(() {
        _perros = lista;
        _sinResultados = lista.isEmpty;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ── Paso 5-11: Ver detalle y votar ────────────────────────────────────
  void _mostrarDetallePerro(PerroModel perro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetallePerroSheet(
        perro: perro,
        controller: _controller,
        onVotoRegistrado: (perroActualizado) {
          // Actualizar el perfil en la lista local en tiempo real (Paso 10)
          setState(() {
            final idx = _perros.indexWhere((p) => p.id == perroActualizado.id);
            if (idx != -1) _perros[idx] = perroActualizado;
          });
        },
      ),
    );
  }

  // ── Colores del nivel de agresividad ──────────────────────────────────
  static Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'PELIGROSO':
        return const Color(0xFFE84C3D);
      case 'MODERADO':
        return const Color(0xFFF48C42);
      case 'INOFENSIVO':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CATÁLOGO DE PERROS',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
        ),
      ),
      // FAB para acceder a CU-11 desde CU-12
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentarPerroScreen()),
          );
          // Refrescar catálogo al volver (un perfil nuevo puede haberse agregado)
          _cargarCatalogo();
        },
        backgroundColor: const Color(0xFFE84C3D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.pets),
        label: const Text('DOCUMENTAR PERRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 12)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE84C3D)))
          : _sinResultados
              ? _buildMensajeVacio()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _perros.length,
                  itemBuilder: (_, i) => _buildTarjetaPerro(_perros[i]),
                ),
    );
  }

  // FE3: Mensaje cuando no hay perfiles registrados
  Widget _buildMensajeVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'No hay perros documentados en el municipio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaPerro(PerroModel perro) {
    final nivel = perro.nivelAgresividad;
    final colorNivel = _colorNivel(nivel);

    return GestureDetector(
      onTap: () => _mostrarDetallePerro(perro),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Fotografía
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                perro.fotoUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100, height: 100,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nivel de agresividad (Paso 6)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorNivel.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        nivel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorNivel, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${perro.tamanio} · ${perro.color}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1C2833)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            perro.zona,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${perro.totalVotos} votos',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget del detalle del perfil + votación (Pasos 6-11 del CU-12) ────────
class _DetallePerroSheet extends StatefulWidget {
  final PerroModel perro;
  final CatalogoPerrosController controller;
  final ValueChanged<PerroModel> onVotoRegistrado;

  const _DetallePerroSheet({
    required this.perro,
    required this.controller,
    required this.onVotoRegistrado,
  });

  @override
  State<_DetallePerroSheet> createState() => _DetallePerroSheetState();
}

class _DetallePerroSheetState extends State<_DetallePerroSheet> {
  late PerroModel _perro;
  bool _enviandoVoto = false;
  bool _yaVoto = false;

  @override
  void initState() {
    super.initState();
    _perro = widget.perro;
    _inicializarEstadoVoto();
  }

  Future<void> _inicializarEstadoVoto() async {
    final prefs = await SharedPreferences.getInstance();
    final tel = prefs.getString('telefono') ?? '';
    if (!mounted) return;
    setState(() {
      _yaVoto = tel.isNotEmpty && _perro.votantes.contains(tel);
    });
  }

  static Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'PELIGROSO':
        return const Color(0xFFE84C3D);
      case 'MODERADO':
        return const Color(0xFFF48C42);
      case 'INOFENSIVO':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  // Pasos 7-8: Solicitar confirmación antes de registrar voto
  void _iniciarVotacion(bool esAgresivo) {
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
              decoration: BoxDecoration(
                color: esAgresivo ? Colors.red.shade50 : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                esAgresivo ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: esAgresivo ? Colors.red.shade700 : Colors.green.shade700,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              esAgresivo ? '¿Confirmar voto: Agresivo?' : '¿Confirmar voto: No agresivo?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu voto ayuda a la comunidad a conocer el comportamiento de este animal. No podrás votar de nuevo en este perfil.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Paso 9: Confirmar voto
                onPressed: () {
                  Navigator.pop(context);
                  _registrarVoto(esAgresivo); // Paso 10
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: esAgresivo ? const Color(0xFFE84C3D) : const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('CONFIRMAR VOTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context), // FA1: solo consultar
              child: Text('CANCELAR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  // Paso 10: Registrar voto y actualizar indicador en tiempo real
  Future<void> _registrarVoto(bool esAgresivo) async {
    setState(() => _enviandoVoto = true);
    try {
      final perroActualizado = await widget.controller.registrarVoto(
        perro: _perro,
        esAgresivo: esAgresivo,
      );
      if (!mounted) return;
      setState(() {
        _perro = perroActualizado;
        _enviandoVoto = false;
        _yaVoto = true; // Ocultar botones y mostrar banner tras votar
      });
      // Notificar al catálogo para actualizar la lista
      widget.onVotoRegistrado(perroActualizado);
      // Paso 11: Mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu voto fue registrado exitosamente.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on VotoDuplicadoException catch (e) {
      // FE1: Voto duplicado
      if (!mounted) return;
      setState(() {
        _enviandoVoto = false;
        _yaVoto = true; // Por si acá no fue detectado antes
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.mensaje),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // FE2: Error de red
      if (!mounted) return;
      setState(() => _enviandoVoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar el voto. Verifica tu conexión e intenta nuevamente.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivel = _perro.nivelAgresividad;
    final colorNivel = _colorNivel(nivel);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotografía (Paso 6)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    _perro.fotoUrl,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nivel de agresividad comunitario (Paso 6)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorNivel.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              nivel,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorNivel, letterSpacing: 0.5),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_perro.totalVotos} votos',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Datos físicos
                      _buildFila(Icons.straighten, 'TAMAÑO', _perro.tamanio),
                      const SizedBox(height: 14),
                      _buildFila(Icons.palette_outlined, 'COLOR', _perro.color),
                      const SizedBox(height: 14),
                      _buildFila(Icons.location_on_outlined, 'ZONA DE AVISTAMIENTO', _perro.zona),

                      if (_perro.observaciones.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildFila(Icons.notes, 'OBSERVACIONES', _perro.observaciones),
                      ],

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 20),

                      // ── Votación (Paso 7) ──
                      const Text(
                        'VOTAR NIVEL DE AGRESIVIDAD',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4A3428), letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu voto actualiza el nivel comunitario en tiempo real.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),

                      if (_enviandoVoto)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFE84C3D)))
                      else if (_yaVoto)
                        // Banner: el usuario ya votó
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.how_to_vote_rounded, color: Colors.orange.shade700, size: 26),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ya emitiste tu voto',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.orange.shade800),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Solo puedes votar una vez por perfil. Gracias por tu participación.',
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _iniciarVotacion(true),
                                icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE84C3D)),
                                label: const Text('AGRESIVO', style: TextStyle(color: Color(0xFFE84C3D), fontWeight: FontWeight.w900, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE84C3D)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _iniciarVotacion(false),
                                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                                label: const Text('NO AGRESIVO', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w900, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF4CAF50)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Botón regresar al catálogo
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text(
                            'REGRESAR AL CATÁLOGO',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black54,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFila(IconData icon, String titulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C2833))),
            ],
          ),
        ),
      ],
    );
  }
}
