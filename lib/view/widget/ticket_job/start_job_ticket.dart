import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/card_widget.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/header_widget.dart';
import '../../../widget/maps_widget.dart';
import '../../../widget/text_field_widget.dart';

class StartJobTicket extends StatefulWidget {

  final ApiResTicket ticket;

  const StartJobTicket({super.key, required this.ticket});

  @override
  State<StartJobTicket> createState() => _StartJobTicket();
}

class _StartJobTicket extends State<StartJobTicket> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      context.read<ListTicketViewmodel>().isLoadingStart = true;
      context.read<ListTicketViewmodel>().resetEvidenceStart();
      context.read<ListTicketViewmodel>().isLoadingStart = false;
    });
  }


  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ListTicketViewmodel>();

    if (viewModel.isLoadingStart) return const Center(child: CircularProgressIndicator());

    final ButtonStyle styleValidateBtn = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
        visualDensity: VisualDensity.compact,
      backgroundColor: viewModel.isValidateComponent && viewModel.urlImgValidate != null? Colors.green.shade600: Colors.blueAccent.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.zero,
    );

    int lenEvidence = viewModel.evidencePhotos.where((img) => img['source'] != 'SCREENSHOT').length;

    String lenEvidencteText = lenEvidence > 0? "[$lenEvidence/6]":"[$lenEvidence/6] mínimo 1.";

    return Screenshot(
      controller: viewModel.screenshotController,
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
              key: viewModel.formKeyStartJob,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header( context,"Iniciar Trabajo", (){
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
                        textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company.toString(), readOnly: true ),
                        const SizedBox(height: 12),
                        textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
                        const SizedBox(height: 12),
                        textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true ),
                        const SizedBox(height: 12),
                        textField(viewModel.descriptionStartController, 'Descripcion', Icons.text_snippet_outlined),
                      ],
                    ),
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
                              'Validación y Ubicación',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Validación de corriente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        Text(
                          'Validación de tierra',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        Text(
                          'Validación de ignición',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          height: 500,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomGoogleMap(
                              deviceId: widget.ticket.unitId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  /// EVIDENCE SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.05),
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
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.green.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Evidencia Antes de Iniciar',
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
                          images: viewModel.evidencePhotos,
                          onImagesChanged: (List<Map<String, String>> images) {
                            setState(() {
                              viewModel.evidencePhotos = images;
                            });
                          },
                          onImageDelete: (deletedItem) {
                            setState(() {
                              if (deletedItem['source'] == 'SCREENSHOT') {
                                viewModel.clearValidation(false);
                              }
                            });
                          },
                          maxImages: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.sendEvidence(context: context, idTicket: widget.ticket.id, ticket: widget.ticket);
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
