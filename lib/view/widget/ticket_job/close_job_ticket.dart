import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instaladores_new/service/response_service.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/card_widget.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/header_widget.dart';
import '../../../widget/text_field_widget.dart';
import '../../../widget/maps_widget.dart';

class CloseJobTicket extends StatefulWidget {

  final ApiResTicket ticket;

  const CloseJobTicket({super.key, required this.ticket});

  @override
  State<CloseJobTicket> createState() => _CloseJobTicket();
}
class _CloseJobTicket extends State<CloseJobTicket> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ListTicketViewmodel>().isLoadingClose = true;
      context.read<ListTicketViewmodel>().resetEvidenceClose();
      context.read<ListTicketViewmodel>().initSocket(widget.ticket.unitId.toString(), widget.ticket.company.toString());
      context.read<ListTicketViewmodel>().isLoadingClose = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ListTicketViewmodel>();

    final ButtonStyle styleValidateBtn = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
      backgroundColor: viewModel.isValidateComponent && viewModel.urlImgComponent != null? Colors.green.shade600: Colors.blueAccent.shade400,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.zero,
    );
    
    // Contamos fotos que NO sean capturas automáticas (mapas o componentes)
    int lenEvidence = viewModel.evidenceClosePhotos.where((img) => 
      img['source'] != 'SCREENSHOT_COMPONENTS' && img['source'] != 'SCREENSHOT_MAPS'
    ).length;

    String lenEvidencteText = "[$lenEvidence/6] mínimo 1.";


    return Screenshot(
      controller: viewModel.screenshotCloseController,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
                key: viewModel.formKeyCloseJob,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header( context,"Cerrar Trabajo", (){
                      viewModel.disconnectSocket();
                      Navigator.pop(context);
                    } ),
                    const SizedBox(height: 20),
                    
                    /// INFO SECTION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Información del Trabajo',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company!, readOnly: true ),
                          const SizedBox(height: 12),
                          textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
                          const SizedBox(height: 12),
                          textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true, ),
                          const SizedBox(height: 12),
                          textField(viewModel.unitModelCloseController, 'Modelo de unidad (*)', Icons.text_snippet_outlined),
                          const SizedBox(height: 12),
                          textField(viewModel.descriptionCloseController, 'Comentario e revisión (*)', Icons.text_snippet_outlined),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [

                                // region VCC
                                OutlinedButton(
                                  onPressed: (){
                                    if( viewModel.vcc != null ) {
                                      print("=> open modal to show img");
                                      return;
                                    }

                                    print("Evidence VCC");
                                    setState(() {
                                      viewModel.vcc = "hola";
                                    });
                                  } ,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: viewModel.vcc == null?  Colors.grey.shade100:Colors.grey,
                                    side: BorderSide(
                                      color: viewModel.vcc == null? Colors.grey.shade100: Colors.green.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                      "VCC"
                                  ),
                                ),
                                // endregion VCC

                                // region GNC
                                OutlinedButton(
                                  onPressed: () {
                                    if( viewModel.gnc != null ) {
                                      print("=> open modal to show img");
                                      return;
                                    }
                                    print("Evidence GNC");
                                    setState(() {
                                      viewModel.gnc = "hola";
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: viewModel.gnc == null? Colors.grey.shade100:Colors.grey,
                                    side: BorderSide(
                                      color: viewModel.gnc == null ? Colors.grey.shade100:Colors.green.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                      "GNC"
                                  ),
                                ),
                                // endregion GNC

                                // region IGNICION
                                OutlinedButton(
                                  onPressed:(){
                                    if( viewModel.ignition != null ) {
                                      print("=> open modal to show img");
                                      return;
                                    }
                                    setState(() {
                                      viewModel.ignition = "hola";
                                    });
                                    print("Evidence IGNICION");
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: viewModel.ignition == null? Colors.grey.shade100:Colors.grey,
                                    side: BorderSide(
                                      color: viewModel.ignition == null? Colors.grey.shade100:Colors.green.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                      "IGNICION"
                                  ),
                                ),
                                // endregion IGNICION

                              ]
                            ),

                            // region UBICACION DEL GPS
                            OutlinedButton(
                              onPressed: (){
                                if( viewModel.gps != null ) {
                                  print("=> open modal to show img");
                                  return;
                                }
                                setState(() {
                                  viewModel.gps = "hola";
                                });
                                print("Evidence UBICACION DEL GPS");
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: viewModel.gps == null ? Colors.grey.shade100:Colors.grey,
                                side: BorderSide(
                                  color:  viewModel.gps == null? Colors.grey.shade100:Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                  "UBICACION DEL GPS"
                              ),
                            ),
                            // endregion UBICACION DEL GPS

                            // region ARMADO DE LA UNIDAD
                            OutlinedButton(
                              onPressed: (){
                                if( viewModel.buildUnit != null ) {
                                  print("=> open modal to show img");
                                  return;
                                }
                                setState(() {
                                  viewModel.buildUnit = "hola";
                                });
                                print("Evidence ARMADO DE LA UNIDAD");
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor:viewModel.buildUnit == null? Colors.grey.shade100:Colors.grey,
                                side: BorderSide(
                                  color: viewModel.buildUnit == null? Colors.grey.shade100:Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                  "ARMADO DE LA UNIDAD"
                              ),
                            ),
                            // endregion ARMADO DE LA UNIDAD

                            // region extra img
                            OutlinedButton(
                              onPressed: (){
                                if( viewModel.extraOne != null ) {
                                  print("=> open modal to show img");
                                  return;
                                }
                                setState(() {
                                  viewModel.extraOne = "hola";
                                });
                                print("Evidence extra img 1");
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: viewModel.extraOne == null? Colors.grey.shade100:Colors.grey,
                                side: BorderSide(
                                  color: viewModel.extraOne == null? Colors.grey.shade100:Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                  "IMAGEN EVIDENCIA OPCIONA 1"
                              ),
                            ),

                            OutlinedButton(
                              onPressed: (){
                                if( viewModel.extraTwo != null ) {
                                  print("=> open modal to show img");
                                  return;
                                }
                                setState(() {
                                  viewModel.extraTwo = "hola";
                                });
                                print("Evidence extra img 2");
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: viewModel.extraTwo == null? Colors.grey.shade100:Colors.grey,
                                side: BorderSide(
                                  color: viewModel.extraTwo == null? Colors.grey.shade100:Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                  "IMAGEN EVIDENCIA OPCIONA 2"
                              ),
                            ),
                            // endregion extra img


                          ]
                        )
                    ),

                    const SizedBox(height: 20),

                    /// VALIDATION SECTION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.blue.shade700,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Validación de Funciones',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: textFieldOnlyRead( label: '', icon: Icons.assignment_turned_in, value: "Valida la función", readOnly: true ),
                              ),
                              const SizedBox(),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isDownloadEnabled && viewModel.urlImgComponent == null
                                      ? () async {
                                    await viewModel.takeScreenshotAndSave(true);
                                    if (mounted && viewModel.urlImgComponent != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Evidencia capturada con éxito')),
                                      );
                                    }
                                  }
                                      : null,
                                  icon: Icon(viewModel.isValidateComponent ? Icons.check_circle : Icons.camera_alt),
                                  label: Text(viewModel.isValidateComponent ? "Evidencia lista" : "Tomar evidencia"),
                                  style: styleValidateBtn,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Flexible(
                                flex: 2,
                                child:  Text(
                                    "Lectoras",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                flex: 3,
                                child: TextFormField(
                                  controller: viewModel.lectorasController,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: "Estado",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Flexible(
                                  flex: 2,
                                  child: Text(
                                      "Botón de pánico",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                  )
                              ),

                              const SizedBox(width: 10),
                              Flexible(
                                flex: 3,
                                child: TextFormField(
                                  controller: viewModel.panicoController,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: "Estado",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      )
                    ),
                    const SizedBox(height: 24),

                    /// LOCATION SECTION

                    SizedBox(
                      height: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomGoogleMap(
                          deviceId: widget.ticket.unitId,
                          isTicketClose: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    /// EVIDENCE SECTION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.orange.shade700,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Evidencia Después de Terminar',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          infoText(
                              text: lenEvidencteText,
                              styles: TextStyle(
                                fontSize: 14,
                                color: lenEvidence > 0? Colors.green.shade600: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              )
                          ),
                          const SizedBox(height: 12),
                          EvidenceGrid(
                            images: viewModel.evidenceClosePhotos,
                            onImagesChanged: (images) {
                              setState(() {
                                viewModel.evidenceClosePhotos = images;
                              });
                            },
                            onImageDelete: (deletedItem) {
                              setState(() {
                                if (deletedItem['source'] == 'SCREENSHOT_COMPONENTS') {
                                  viewModel.urlImgComponent = null;
                                  viewModel.isValidateComponent = false;
                                } else if (deletedItem['source'] == 'SCREENSHOT_MAPS') {
                                  viewModel.urlImgMaps = null;
                                  viewModel.isEvidenceUnitUserClose = false;
                                }
                              });
                            },
                            maxImages: 8, // Aumentado para dar espacio a las automáticas
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        viewModel.sendEvidenceClose(context: context, idTicket: widget.ticket.id, ticket: widget.ticket);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Enviar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
            ),
          ),
        ),
      ),
    );
  }

}
