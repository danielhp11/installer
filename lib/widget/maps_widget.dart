import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaladores_new/viewModel/list_ticket_viewmodel.dart';
import 'package:instaladores_new/widget/card_widget.dart';
import 'package:instaladores_new/widget/text_field_widget.dart';
import 'package:provider/provider.dart';

import '../service/response_service.dart';

class CustomGoogleMap extends StatefulWidget {
  final deviceId;
  final double zoom;

  const CustomGoogleMap({
    Key? key,
    this.deviceId,
    this.zoom = 16,
  }) : super(key: key);

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  GoogleMapController? _mapController;

  String nameUnit = "Cargando ...";
  double latUnit = 20.543296;
  double longUnit = -103.475132;
  bool status = true;
  String date = "Cargando ...";
  double battery = 0.0;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {

      final responseStatus = await context.read<ListTicketViewmodel>().getStatusDevice(
          idDevice: int.parse(widget.deviceId.toString())
      );

      final response = await context.read<ListTicketViewmodel>().getPositionDevice(
          idDevice: int.parse(widget.deviceId.toString())
      );

      if (mounted) {
        setState(() {
          nameUnit = responseStatus['name'] as String;
          latUnit = response['latitude'] as double;
          longUnit = response['longitude'] as double;
          status = response['attributes']['ignition'] as bool;
          battery = response['attributes']['battery'] as double;
          date = response['deviceTime'] as String;
        });

        // Mover la cámara a la nueva posición
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(latUnit, longUnit)),
        );
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    final ListTicketViewmodel viewModel = context.watch<ListTicketViewmodel>();

    return card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    print("Text button pressed");
                  },
                  child: const Text("Evidencia de posición de la unidad e instalador"),
                )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: IconButton(
                  onPressed: () {
                    print("Icon pressed");
                  },
                  icon: Image.asset(
                    'assets/images/icons/motor.png',
                    width: 24,
                    height: 24,
                  ),
                )

              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latUnit, longUnit),
                  zoom: widget.zoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: {
                  Marker(
                    markerId: const MarkerId("main_marker"),
                    position: LatLng(latUnit, longUnit),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
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
                    child: infoText(
                      text: "Unidad: ${nameUnit}",
                      textAlign: TextAlign.start,
                      styles: const TextStyle(
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
                    child: infoText(
                      text: status? "Encendida":"Apagada",
                      styles: TextStyle(
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
                  infoText(
                    text: "Fecha: $date",
                    styles: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.battery_charging_full, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  infoText(
                    text: "$battery V",
                    styles: TextStyle(
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
