import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaladores_new/viewModel/list_ticket_viewmodel.dart';
import 'package:instaladores_new/widget/card_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CustomGoogleMap extends StatefulWidget {
  final deviceId;
  final isTicketClose;
  final double zoom;

  const CustomGoogleMap({
    Key? key,
    this.deviceId,
    this.zoom = 16,
    this.isTicketClose = false,
  }) : super(key: key);

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _customIcon;

  String nameUnit = "Cargando ...";
  double latUnit = 20.543296;
  double longUnit = -103.475132;
  bool status = true;
  String date = "Cargando ...";
  double battery = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();

    Future.microtask(() async {
      try {
        final viewModel = context.read<ListTicketViewmodel>();
        final responseStatus = await viewModel.getStatusDevice(
            idDevice: int.parse(widget.deviceId.toString())
        );

        final response = await viewModel.getPositionDevice(
            idDevice: int.parse(widget.deviceId.toString())
        );

        if (mounted) {
          setState(() {
            nameUnit = responseStatus['name'] as String;
            latUnit = response['latitude'] as double;
            longUnit = response['longitude'] as double;
            status = response['attributes']['ignition'] as bool;
            battery = response['attributes']['battery'] as double;
            date = parseDateDevice(response['deviceTime'] as String);
          });

          // 1. Obtenemos la proximidad y la ubicación del usuario
          await viewModel.checkProximity(latUnit, longUnit);
          
          // 2. Ajustamos la cámara para ver ambos puntos
          _updateCameraBounds();
        }
      } catch (e) {
        debugPrint("Error al obtener posición: $e");
      }
    });
  }

  /// Ajusta el zoom y centro del mapa para mostrar tanto la unidad como al usuario
  void _updateCameraBounds() {
    if (_mapController == null) return;
    
    final viewModel = context.read<ListTicketViewmodel>();
    
    if (viewModel.userLat != null && viewModel.userLon != null) {
      // Calculamos los límites que contienen ambos puntos
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          latUnit < viewModel.userLat! ? latUnit : viewModel.userLat!,
          longUnit < viewModel.userLon! ? longUnit : viewModel.userLon!,
        ),
        northeast: LatLng(
          latUnit > viewModel.userLat! ? latUnit : viewModel.userLat!,
          longUnit > viewModel.userLon! ? longUnit : viewModel.userLon!,
        ),
      );

      // Animamos la cámara con un padding de 80 para que no queden pegados a las orillas
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } else {
      // Si no hay ubicación del usuario, solo centramos en la unidad
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(latUnit, longUnit)),
      );
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadCustomMarker() async {
    try {
      final Uint8List markerIcon = await getBytesFromAsset('assets/images/icons/bus_icon.png', 100);
      if (mounted) {
        setState(() {
          _customIcon = BitmapDescriptor.fromBytes(markerIcon);
        });
      }
    } catch (e) {
      debugPrint("Error cargando el marcador personalizado: $e");
    }
  }

  String parseDateDevice (String dateStr){
    DateTime parsedDate = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListTicketViewmodel>();
    final bool hasEvidence = viewModel.isEvidenceUnitUserClose || viewModel.isEvidenceUnitUserStart;

    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("unit_marker"),
        position: LatLng(latUnit, longUnit),
        infoWindow: InfoWindow(
          title: "Unidad: $nameUnit", 
          snippet: "Distancia: ${viewModel.currentDistance.toStringAsFixed(2)}m"
        ),
        icon: _customIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    if (viewModel.userLat != null && viewModel.userLon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user_marker"),
          position: LatLng(viewModel.userLat!, viewModel.userLon!),
          infoWindow: const InfoWindow(title: "Tu ubicación"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    Set<Polyline> polylines = {};
    if (viewModel.userLat != null && viewModel.userLon != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("distance_line"),
          points: [
            LatLng(latUnit, longUnit),
            LatLng(viewModel.userLat!, viewModel.userLon!),
          ],
          color: Colors.blueAccent,
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    return card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: viewModel.isNearUnit 
                    ? () async {
                        await viewModel.takeScreenshotAndSaveMaps(widget.isTicketClose);
                      }
                    : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: viewModel.isNearUnit ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
                    side: BorderSide(
                      color: viewModel.isNearUnit 
                        ? (hasEvidence ? Colors.green : Colors.blue) 
                        : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    viewModel.isNearUnit 
                      ? "Capturar evidencia (Cerca)" 
                      : "Fuera de rango (${viewModel.currentDistance.toStringAsFixed(1)}m)",
                    style: TextStyle(
                      color: viewModel.isNearUnit ? Colors.green.shade800 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: IconButton(
                  onPressed: () async {
                    await viewModel.checkProximity(latUnit, longUnit);
                    _updateCameraBounds();
                  },
                  icon: Image.asset(
                    'assets/images/icons/motor.png',
                    width: 44,
                    height: 44,
                  ),
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latUnit, longUnit),
                      zoom: widget.zoom,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Intentamos ajustar al cargar el mapa
                      _updateCameraBounds();
                    },
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  if (viewModel.userLat != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Text(
                          "Distancia: ${viewModel.currentDistance.toStringAsFixed(2)} metros",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Unidad: $nameUnit",
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status? "Encendida":"Apagada",
                      style: TextStyle(
                        fontSize: 11,
                        color: status? Colors.green.shade700:Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "Fecha: $date",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.battery_charging_full, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "$battery V",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
