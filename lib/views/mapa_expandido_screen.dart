import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/mapa_controller.dart';
import '../controllers/punto_seguro_controller.dart';
import '../models/alerta_model.dart';
import '../services/usuario_service.dart';
import '../widgets/detalle_incidente_widget.dart';

class MapaExpandidoScreen extends StatefulWidget {
  final double? latitud;
  final double? longitud;

  const MapaExpandidoScreen({super.key, this.latitud, this.longitud});

  @override
  State<MapaExpandidoScreen> createState() => _MapaExpandidoScreenState();
}

class _MapaExpandidoScreenState extends State<MapaExpandidoScreen> {
  late MapaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapaController();

    _controller.onMapaActualizado = () {
      if (mounted) setState(() {});
    };

    _controller.onMostrarDetalle = (alerta) {
      _mostrarDetalleIncidente(alerta);
    };

    _controller.onMostrarDetallePuntoSeguro = (data) {
      _mostrarDetallePuntoSeguro(data);
    };

    _controller.obtenerUbicacionActual();
    _controller.cargarAlertas();
    _controller.cargarPuntosSeguros();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mostrarDetalleIncidente(AlertaModel alerta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DetalleIncidenteWidget(
          alerta: alerta,
          controller: _controller,
          onVerEnMapa: () {
            _controller.moverCamara(alerta.latitud, alerta.longitud, 17);
          },
        );
      },
    );
  }

  void _mostrarDetallePuntoSeguro(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PuntoSeguroSheet(
        data: data,
        mapaController: _controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centroInicial = widget.latitud != null && widget.longitud != null
        ? LatLng(widget.latitud!, widget.longitud!)
        : const LatLng(22.7415, -102.3716); // Trancoso default

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            style: '[{"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]',
            initialCameraPosition: CameraPosition(
              target: centroInicial,
              zoom: 14.5,
            ),
            markers: _controller.markers,
            polylines: _controller.polylines,
            myLocationEnabled: _controller.gpsActivo,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller.mapController = controller;
            },
          ),
          _buildTopBar(),
          _buildLegend(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF2C2C2C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'MAPA DE ALERTAS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C2833),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.gpsActivo
                          ? const Color(0xFFF4C542)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _controller.gpsActivo ? 'GPS ACTIVO' : 'GPS INACTIVO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
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
  }

  Widget _buildLegend() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.mostrarAlertas = !_controller.mostrarAlertas;
                  _controller.onMapaActualizado?.call();
                });
              },
              child: Opacity(
                opacity: _controller.mostrarAlertas ? 1.0 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(const Color(0xFFE84C3D), 'ALTO RIESGO'),
                    const SizedBox(height: 6),
                    _buildLegendItem(const Color(0xFFF48C42), 'MEDIO RIESGO'),
                    const SizedBox(height: 6),
                    _buildLegendItem(const Color(0xFFF4C542), 'BAJO RIESGO'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.mostrarPuntosSeguros = !_controller.mostrarPuntosSeguros;
                  _controller.onMapaActualizado?.call();
                });
              },
              child: Opacity(
                opacity: _controller.mostrarPuntosSeguros ? 1.0 : 0.4,
                child: _buildLegendItem(Colors.green.shade600, 'PUNTO SEGURO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: GestureDetector(
        onTap: () => _controller.centrarEnMiUbicacion(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.red.shade400,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─── CU-10: Sheet de validación de punto seguro ───────────────────────────────
class _PuntoSeguroSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final MapaController mapaController;
  const _PuntoSeguroSheet({required this.data, required this.mapaController});

  @override
  State<_PuntoSeguroSheet> createState() => _PuntoSeguroSheetState();
}

class _PuntoSeguroSheetState extends State<_PuntoSeguroSheet> {
  final _ctrl = PuntoSeguroController();
  bool _cargando = true;
  bool? _votoActual; // null = sin voto, true = confirmó, false = descartó
  bool _esPropio = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    final userId = UsuarioService.userId;
    final ownerId = widget.data['userId'] as String? ?? '';
    final puntoId = widget.data['id'] as String? ?? '';

    // FE3: es propietario
    if (ownerId == userId) {
      setState(() { _esPropio = true; _cargando = false; });
      return;
    }

    // FE1: ya votó
    final voto = await _ctrl.obtenerVotoUsuario(puntoId, userId);
    if (mounted) setState(() { _votoActual = voto; _cargando = false; });
  }

  Future<void> _onVotar(bool esSeguro) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(esSeguro ? Icons.verified_user_outlined : Icons.report_outlined,
                    color: const Color(0xFFB71C1C), size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Confirmar validación?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                esSeguro
                    ? 'Estás por confirmar que este punto es seguro. ¿Deseas continuar?'
                    : 'Estás por reportar que este punto no existe o es falso. ¿Deseas continuar?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _enviando = true);
    try {
      await _ctrl.registrarVoto(
        puntoId: widget.data['id'] as String,
        userId: UsuarioService.userId,
        esSeguro: esSeguro,
      );
      if (mounted) {
        setState(() { _votoActual = esSeguro; _enviando = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(esSeguro ? '¡Gracias! Confirmaste que este punto es seguro.' : 'Reporte enviado. Gracias por tu participación.'),
          backgroundColor: esSeguro ? Colors.green.shade700 : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('No se pudo enviar la validación. Verifica tu conexión.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final confirmaciones = (data['confirmaciones'] as num?)?.toInt() ?? 0;
    final descartes = (data['descartes'] as num?)?.toInt() ?? 0;
    final total = confirmaciones + descartes;
    final porcentaje = total > 0 ? (confirmaciones / total * 100).round() : 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 8),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Título
                      const Text('PUNTO SEGURO',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                            color: Color(0xFF1C2833), height: 1.1)),
                      const SizedBox(height: 20),

                      // Tarjeta info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['nombre'] ?? 'Sin nombre',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C2833))),
                                    const SizedBox(height: 4),
                                    Text(data['tipo'] ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB71C1C))),
                                  ],
                                )),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                  child: Icon(Icons.verified_user_outlined, color: Colors.green.shade700, size: 26),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _infoRow(Icons.access_time_outlined, 'DISPONIBILIDAD', data['disponibilidad'] ?? ''),
                            if ((data['vigilancia24h'] as bool? ?? false) || (data['botonPanico'] as bool? ?? false)) ...[
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, children: [
                                if (data['vigilancia24h'] as bool? ?? false)
                                  _chip(Icons.videocam_outlined, 'VIGILANCIA 24/7'),
                                if (data['botonPanico'] as bool? ?? false)
                                  _chip(Icons.phone_in_talk_outlined, 'BOTÓN DE PÁNICO'),
                              ]),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Participación Comunitaria
                      const Text('PARTICIPACIÓN COMUNITARIA',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                            color: Color(0xFF4A3428), letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _statCol(Icons.check_circle_outline, '$confirmaciones vecinos lo\nhan confirmado', Colors.green.shade600)),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            Expanded(child: _statCol(Icons.cancel_outlined, '$descartes lo han\ndescartado', Colors.red.shade400)),
                          ],
                        ),
                      ),

                      if (total > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? confirmaciones / total : 0,
                            minHeight: 6,
                            backgroundColor: Colors.red.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$porcentaje% de confiabilidad',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],

                      const SizedBox(height: 20),

                      // Panel de votación
                      if (_cargando)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
                      else if (_esPropio)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text('No puedes validar tus propios puntos seguros.',
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w600))),
                          ]),
                        )
                      else if (_votoActual != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(children: [
                            Icon(Icons.how_to_vote_outlined, color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Ya emitiste tu opinión sobre este punto seguro.',
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w600))),
                          ]),
                        )
                      else
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _enviando ? null : () => _onVotar(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0DC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.4)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.check_circle_outline, color: Colors.amber.shade800, size: 18),
                                  const SizedBox(width: 6),
                                  Text('SÍ ES\nSEGURO',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                                        color: Colors.amber.shade900, height: 1.2),
                                    textAlign: TextAlign.center),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _enviando ? null : () => _onVotar(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                                  const SizedBox(width: 6),
                                  Text('NO\nEXISTE',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                                        color: Colors.grey.shade700, height: 1.2),
                                    textAlign: TextAlign.center),
                                ]),
                              ),
                            ),
                          ),
                        ]),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Botón CÓMO LLEGAR fijo al fondo
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.mapaController.gpsActivo ? () {
                      Navigator.pop(context);
                      widget.mapaController.trazarRuta(data['latitud'], data['longitud']);
                    } : null,
                    icon: const Icon(Icons.navigation_outlined, color: Colors.white, size: 20),
                    label: Text(
                      widget.mapaController.gpsActivo ? 'CÓMO LLEGAR' : 'GPS NO DISPONIBLE',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String titulo, String valor) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: const Color(0xFF4A3428)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
            color: Color(0xFF4A3428), letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C2833))),
      ])),
    ]);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: const Color(0xFF4A3428)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
            color: Color(0xFF4A3428), letterSpacing: 0.4)),
      ]),
    );
  }

  Widget _statCol(IconData icon, String texto, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, height: 1.3),
          textAlign: TextAlign.center),
    ]);
  }
}

/*import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/mapa_controller.dart';
import '../models/alertaModel.dart';
import '../widgets/detalle_incidente_widget.dart';

class MapaExpandidoScreen extends StatefulWidget {
  final double? latitud;
  final double? longitud;

  const MapaExpandidoScreen({super.key, this.latitud, this.longitud});

  @override
  State<MapaExpandidoScreen> createState() => _MapaExpandidoScreenState();
}

class _MapaExpandidoScreenState extends State<MapaExpandidoScreen> {
  late MapaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapaController();
    
    _controller.onMapaActualizado = () {
      if (mounted) setState(() {});
    };
    
    _controller.onMostrarDetalle = (alerta) {
      _mostrarDetalleIncidente(alerta);
    };
    
    _controller.obtenerUbicacionActual();
    _controller.cargarAlertas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mostrarDetalleIncidente(AlertaModel alerta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DetalleIncidenteWidget(
          alerta: alerta,
          controller: _controller,
          onVerEnMapa: () {
            _controller.moverCamara(alerta.latitud, alerta.longitud, 17);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final centroInicial = widget.latitud != null && widget.longitud != null
        ? LatLng(widget.latitud!, widget.longitud!)
        : const LatLng(22.7415, -102.3716);

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centroInicial,
              zoom: 14.5,
            ),
            markers: _controller.markers,
            myLocationEnabled: _controller.gpsActivo,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller.mapController = controller;
            },
          ),
          _buildTopBar(),
          _buildLegend(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'MAPA DE ALERTAS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C2833),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.gpsActivo
                          ? const Color(0xFFF4C542)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _controller.gpsActivo ? 'GPS ACTIVO' : 'GPS INACTIVO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
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
  }

  Widget _buildLegend() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(const Color(0xFFE84C3D), 'ALTO RIESGO'),
            const SizedBox(height: 6),
            _buildLegendItem(const Color(0xFFF48C42), 'MEDIO RIESGO'),
            const SizedBox(height: 6),
            _buildLegendItem(const Color(0xFFF4C542), 'BAJO RIESGO'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Text(
                    'Buscar zona o calle...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _controller.centrarEnMiUbicacion(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location,
                color: Colors.red.shade400,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/

/*import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alerta_model.dart';

class MapaExpandidoScreen extends StatefulWidget {
  final double? latitud;
  final double? longitud;

  const MapaExpandidoScreen({super.key, this.latitud, this.longitud});

  @override
  State<MapaExpandidoScreen> createState() => _MapaExpandidoScreenState();
}

class _MapaExpandidoScreenState extends State<MapaExpandidoScreen> {
  GoogleMapController? _mapController;
  Position? _miPosicion;
  bool _gpsActivo = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _cargarAlertas();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _miPosicion = posicion;
          _gpsActivo = true;
        });
      }
    } catch (_) {}
  }

  void _cargarAlertas() {
    FirebaseFirestore.instance.collection('alertas').snapshots().listen((
      snapshot,
    ) async {
      if (!mounted) return;

      final alertas = snapshot.docs
          .map((doc) => Alerta.fromFirestore(doc))
          .toList();

      final Set<Marker> nuevosMarkers = {};

      for (final alerta in alertas) {
        if (alerta.latitud == 0.0 && alerta.longitud == 0.0) continue;

        final icono = await _crearIconoPersonalizado(alerta.riesgo);

        nuevosMarkers.add(
          Marker(
            markerId: MarkerId(alerta.id),
            position: LatLng(alerta.latitud, alerta.longitud),
            icon: icono,
            onTap: () => _mostrarDetalleIncidente(alerta),
          ),
        );
      }

      if (mounted) {
        setState(() => _markers = nuevosMarkers);
      }
    });
  }

  Future<BitmapDescriptor> _crearIconoPersonalizado(String riesgo) async {
    final color = _colorParaRiesgo(riesgo);
    final size = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 2),
      size / 2 - 6,
      shadowPaint,
    );

    // Borde blanco
    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Círculo de color
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, circlePaint);

    // Icono de advertencia (triángulo con !)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Triángulo
    final path = Path();
    final cx = size / 2;
    final cy = size / 2;
    path.moveTo(cx, cy - 22);
    path.lineTo(cx + 20, cy + 14);
    path.lineTo(cx - 20, cy + 14);
    path.close();
    canvas.drawPath(path, iconPaint);

    // Signo de exclamación dentro del triángulo
    final exclamationPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Línea del !
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 5, height: 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, exclamationPaint);

    // Punto del !
    canvas.drawCircle(Offset(cx, cy + 10), 3, exclamationPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes, width: 44, height: 44);
  }

  Color _colorParaRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return const Color(0xFFE84C3D);
      case 'MEDIO':
        return const Color(0xFFF48C42);
      case 'BAJO':
        return const Color(0xFFF4C542);
      default:
        return const Color(0xFFF48C42);
    }
  }

  String _etiquetaRiesgo(String riesgo) {
    switch (riesgo.toUpperCase()) {
      case 'ALTO':
        return 'Rojo - Alto';
      case 'MEDIO':
        return 'Naranja - Medio';
      case 'BAJO':
        return 'Amarillo - Bajo';
      default:
        return riesgo;
    }
  }

  String _tiempoTranscurrido(Timestamp fecha) {
    final diff = DateTime.now().difference(fecha.toDate());
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds} seg';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  void _centrarEnMiUbicacion() {
    if (_miPosicion != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_miPosicion!.latitude, _miPosicion!.longitude),
          15.5,
        ),
      );
    }
  }

  void _mostrarDetalleIncidente(Alerta alerta) {
    final color = _colorParaRiesgo(alerta.riesgo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Título
                      const Text(
                        'Detalles del Incidente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C2833),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Ubicación
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alerta.direccion.isNotEmpty
                                  ? alerta.direccion
                                  : '${alerta.latitud.toStringAsFixed(4)}, ${alerta.longitud.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Card nivel de riesgo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                color: color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NIVEL DE RIESGO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _etiquetaRiesgo(alerta.riesgo),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Hora y Emisor
                      Row(
                        children: [
                          // Hora
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 22,
                                    color: Colors.orange.shade300,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'HORA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tiempoTranscurrido(alerta.fecha),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Emisor
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 22,
                                    color: Colors.brown.shade300,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'EMISOR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alerta.emisor,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Alcance
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // Avatares placeholder
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: Stack(
                                children: [
                                  _buildAvatar(0, Icons.person),
                                  Positioned(
                                    left: 18,
                                    child: _buildAvatar(0, Icons.person),
                                  ),
                                  Positioned(
                                    left: 36,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade300,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALCANCE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade400,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Text(
                                    'X Vecinos Notificados',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C2833),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.groups,
                              size: 28,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón ver en mapa completo
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(alerta.latitud, alerta.longitud),
                                17,
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text(
                            'VER EN MAPA COMPLETO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF48C42),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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
          },
        );
      },
    );
  }

  Widget _buildAvatar(int index, IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.brown.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centroInicial = widget.latitud != null && widget.longitud != null
        ? LatLng(widget.latitud!, widget.longitud!)
        : const LatLng(22.7415, -102.3716); // Trancoso default

    return Scaffold(
      body: Stack(
        children: [
          // Mapa a pantalla completa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centroInicial,
              zoom: 14.5,
            ),
            markers: _markers,
            myLocationEnabled: _gpsActivo,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Barra superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Botón de regreso
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2C2C2C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MAPA DE ALERTAS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2833),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),

                  // GPS Activo indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gpsActivo
                                ? const Color(0xFFF4C542)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _gpsActivo ? 'GPS ACTIVO' : 'GPS INACTIVO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leyenda de colores
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeyendaItem(const Color(0xFFE84C3D), 'ALTO RIESGO'),
                  const SizedBox(height: 6),
                  _buildLeyendaItem(const Color(0xFFF48C42), 'MEDIO RIESGO'),
                  const SizedBox(height: 6),
                  _buildLeyendaItem(const Color(0xFFF4C542), 'BAJO RIESGO'),
                ],
              ),
            ),
          ),

          // Barra de búsqueda inferior + botón centrar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Row(
              children: [
                // Barra de búsqueda
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade400),
                        const SizedBox(width: 10),
                        Text(
                          'Buscar zona o calle...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón centrar en mi ubicación
                GestureDetector(
                  onTap: _centrarEnMiUbicacion,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.red.shade400,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}
*/
