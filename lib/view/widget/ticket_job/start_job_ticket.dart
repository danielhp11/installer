import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/card_widget.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/header_widget.dart';
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

    Future.microtask(() {
      context.read<ListTicketViewmodel>().isLoadingStart = true;
      context.read<ListTicketViewmodel>().resetEvidenceStart();
      context.read<ListTicketViewmodel>().initSocket(widget.ticket.unitId, widget.ticket.company!);
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
                  header( context,"Iniciar ticket", (){
                    viewModel.disconnectSocket();
                    Navigator.pop(context);
                  } ),
                  const SizedBox(height: 16),
                  textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company.toString(), readOnly: true ),
                  const SizedBox(height: 16),
                  textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
                  const SizedBox(height: 16),
                  textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true ),
                  const SizedBox(height: 10),
                  textField(viewModel.descriptionStartController, 'Descripcion', Icons.text_snippet_outlined),
                  const SizedBox(height: 10),
                  card(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: textFieldOnlyRead( label: '', icon: Icons.assignment_turned_in, value: "Valida la función", readOnly: true ),
                              ),
                              const SizedBox(),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isDownloadEnabled && viewModel.urlImgValidate == null
                                    ? () async {
                                        await viewModel.takeScreenshotAndSave(false);
                                        if (mounted && viewModel.urlImgValidate != null) {
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
                              Expanded(
                                child:  infoText(
                                    text: "Lectoras",
                                    styles: const TextStyle(
                                      fontSize: 17,
                                    )
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: viewModel.lectorasController,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: "Estado",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: infoText(
                                      text: "Botón de pánico",
                                      styles: const TextStyle(
                                        fontSize: 17,
                                      )
                                  )
                              ),

                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: viewModel.panicoController,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: "Estado",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                    )
                  ),
                  const SizedBox(height: 10),
                  infoText(
                      text: lenEvidencteText,
                      styles: TextStyle(
                        fontSize: 14,
                        color: lenEvidence > 0? Colors.green.shade600: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      )
                  ),
                  const SizedBox(height: 3),
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
                  const SizedBox(height: 16),
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
