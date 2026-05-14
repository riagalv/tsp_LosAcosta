import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/punto_seguro_model.dart';
import '../controllers/punto_seguro_controller.dart';
import '../services/usuario_service.dart';

class RegistrarPuntoSeguroScreen extends StatefulWidget {
  final PuntoSeguro? puntoExistente;
  final bool modoEdicion;
  const RegistrarPuntoSeguroScreen({
    super.key,
    this.puntoExistente,
    this.modoEdicion = false,
  });

  @override
  State<RegistrarPuntoSeguroScreen> createState() => _RegistrarPuntoSeguroScreenState();
}

class _RegistrarPuntoSeguroScreenState extends State<RegistrarPuntoSeguroScreen> {
  final TextEditingController _nombreController = TextEditingController();
  
  String _tipoSeleccionado = '';
  String _disponibilidadSeleccionada = '';
  bool _vigilancia24h = false;
  bool _botonPanico = false;
  bool _guardando = false;

  Position? _posicion;
  bool _cargandoUbicacion = true;
  String _ubicacionTexto = 'Buscando GPS...';
  
  @override
  void initState() {
    super.initState();
    if (widget.modoEdicion && widget.puntoExistente != null) {
      final p = widget.puntoExistente!;
      _nombreController.text = p.nombre;
      _tipoSeleccionado = p.tipo;
      _disponibilidadSeleccionada = p.disponibilidad;
      _vigilancia24h = p.vigilancia24h;
      _botonPanico = p.botonPanico;
      _cargandoUbicacion = false;
      _posicion = Position(
        latitude: p.latitud,
        longitude: p.longitud,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      _obtenerUbicacion();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _ubicacionTexto = 'GPS deshabilitado';
          _cargandoUbicacion = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _ubicacionTexto = 'Permiso denegado';
            _cargandoUbicacion = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _ubicacionTexto = 'Permiso denegado permanentemente';
          _cargandoUbicacion = false;
        });
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _posicion = posicion;
          _cargandoUbicacion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ubicacionTexto = 'Error al obtener ubicación';
          _cargandoUbicacion = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_nombreController.text.isNotEmpty || 
        _tipoSeleccionado.isNotEmpty || 
        _disponibilidadSeleccionada.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Descargar registro?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Si sales ahora, perderás la información que has ingresado para este punto seguro.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, false), // Continuar
                    child: const Text('CONTINUAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => Navigator.pop(context, true), // Descartar
                    child: const Text('DESCARTAR', style: TextStyle(color: Color(0xFF4A3428), fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return shouldPop ?? false;
    }
    return true;
  }

  void _ajustarMarcador() async {
    if (_posicion == null) return;
    
    final LatLng? nuevaUbicacion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarUbicacionScreen(
          ubicacionInicial: LatLng(_posicion!.latitude, _posicion!.longitude),
        ),
      ),
    );

    if (nuevaUbicacion != null) {
      setState(() {
        _posicion = Position(
          latitude: nuevaUbicacion.latitude,
          longitude: nuevaUbicacion.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
    }
  }

  void _guardarPuntoSeguro() async {
    if (_nombreController.text.trim().isEmpty ||
        _tipoSeleccionado.isEmpty ||
        _disponibilidadSeleccionada.isEmpty ||
        _posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, completa todos los campos y asegúrate de tener GPS activo.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C))),
    );

    try {
      if (widget.modoEdicion && widget.puntoExistente != null) {
        await PuntoSeguroController().actualizarPuntoSeguro(
          id: widget.puntoExistente!.id,
          nombre: _nombreController.text.trim(),
          tipo: _tipoSeleccionado,
          direccion: '',
          disponibilidad: _disponibilidadSeleccionada,
          latitud: _posicion!.latitude,
          longitud: _posicion!.longitude,
          vigilancia24h: _vigilancia24h,
          botonPanico: _botonPanico,
        );
        if (mounted) {
          Navigator.pop(context); // cerrar loading
          setState(() => _guardando = false);
          await showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline, color: Colors.red.shade400, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '¡Actualización Exitosa!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'La información del punto seguro ha sido actualizada correctamente.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (mounted) Navigator.pop(context);
        }
      } else {
        await FirebaseFirestore.instance.collection('puntos_seguros').add({
          'nombre': _nombreController.text.trim(),
          'tipo': _tipoSeleccionado,
          'disponibilidad': _disponibilidadSeleccionada,
          'latitud': _posicion!.latitude,
          'longitud': _posicion!.longitude,
          'vigilancia24h': _vigilancia24h,
          'botonPanico': _botonPanico,
          'fecha_registro': FieldValue.serverTimestamp(),
          'userId': UsuarioService.userId,
        });
        if (mounted) {
          Navigator.pop(context);
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Punto seguro registrado exitosamente.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.modoEdicion ? 'EDITAR PUNTO' : 'REGISTRAR PUNTO',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
              ),
              const Text(
                'SEGURO',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 18,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ayuda a la comunidad',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C2833)),
              ),
              const SizedBox(height: 12),
              Text(
                'Completa los detalles para dar de alta un nuevo espacio seguro en la red de ALERTACAN.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 32),

              // Nombre
              _buildSeccionTitulo('NOMBRE DEL LUGAR'),
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej. Veterinaria El Refugio',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB71C1C), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 32),

              // Tipo
              _buildSeccionTitulo('TIPO DE LUGAR'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTipoCard('Casa', Icons.home)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTipoCard('Negocio', Icons.store)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTipoCard('Establecimiento', Icons.domain)),
                ],
              ),
              const SizedBox(height: 32),

              // Mapa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSeccionTitulo('CONFIRMAR UBICACIÓN'),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text('GPS ACTIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.brown.shade700, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cargandoUbicacion
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(strokeWidth: 2),
                              const SizedBox(height: 12),
                              Text(_ubicacionTexto, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      : _posicion != null
                          ? Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_posicion!.latitude, _posicion!.longitude),
                                    zoom: 16,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('punto_seguro'),
                                      position: LatLng(_posicion!.latitude, _posicion!.longitude),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  myLocationEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _ajustarMarcador,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                                        ],
                                      ),
                                      child: const Text(
                                        'AJUSTAR MARCADOR',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(child: Text('Ubicación no disponible', style: TextStyle(color: Colors.grey.shade500))),
                ),
              ),
              const SizedBox(height: 32),

              // Disponibilidad
              _buildSeccionTitulo('DISPONIBILIDAD'),
              const SizedBox(height: 16),
              _buildDisponibilidadCard('Siempre disponible', 'Acceso las 24 horas del día', Icons.access_time_filled),
              const SizedBox(height: 12),
              _buildDisponibilidadCard('Solo de día', 'Horario comercial (8:00 AM - 8:00 PM)', Icons.wb_sunny_rounded),
              const SizedBox(height: 12),
              _buildDisponibilidadCard('Solo de noche', 'Servicio nocturno (8:00 PM - 8:00 AM)', Icons.nightlight_round),
              const SizedBox(height: 32),

              // Atributos de seguridad
              _buildSeccionTitulo('ATRIBUTOS DE SEGURIDAD'),
              const SizedBox(height: 12),
              _buildSwitchRow(
                icon: Icons.videocam_outlined,
                label: 'Vigilancia 24/7',
                value: _vigilancia24h,
                onChanged: (v) => setState(() => _vigilancia24h = v),
              ),
              const SizedBox(height: 8),
              _buildSwitchRow(
                icon: Icons.phone_in_talk_outlined,
                label: 'Botón de pánico',
                value: _botonPanico,
                onChanged: (v) => setState(() => _botonPanico = v),
              ),

              const SizedBox(height: 48),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarPuntoSeguro,
                  icon: Icon(widget.modoEdicion ? Icons.save_outlined : Icons.verified, size: 20),
                  label: Text(
                    widget.modoEdicion ? 'GUARDAR CAMBIOS' : 'CONFIRMAR REGISTRO',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
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

  Widget _buildTipoCard(String tipo, IconData icon) {
    final isSelected = _tipoSeleccionado == tipo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoSeleccionado = tipo;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB71C1C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFB71C1C) : Colors.grey.shade200, width: 1.5),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFB71C1C).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFFB71C1C), size: 28),
            const SizedBox(height: 8),
            Text(
              tipo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisponibilidadCard(String titulo, String subtitulo, IconData icon) {
    final isSelected = _disponibilidadSeleccionada == titulo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _disponibilidadSeleccionada = titulo;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A3428), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFB71C1C) : Colors.grey.shade300, width: isSelected ? 7 : 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A3428), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFB71C1C),
          ),
        ],
      ),
    );
  }
}

class SeleccionarUbicacionScreen extends StatefulWidget {
  final LatLng ubicacionInicial;
  const SeleccionarUbicacionScreen({super.key, required this.ubicacionInicial});

  @override
  State<SeleccionarUbicacionScreen> createState() => _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState extends State<SeleccionarUbicacionScreen> {
  late LatLng _ubicacionActual;

  @override
  void initState() {
    super.initState();
    _ubicacionActual = widget.ubicacionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Ubicación', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _ubicacionActual, zoom: 17),
            onCameraMove: (position) {
              _ubicacionActual = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0), // Ajustar por el pincho del icono
              child: Icon(Icons.location_on, size: 50, color: const Color(0xFFB71C1C)),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _ubicacionActual),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: const Text('CONFIRMAR UBICACIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
