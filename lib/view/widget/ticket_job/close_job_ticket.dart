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
      backgroundColor: viewModel.isValidateComponent && viewModel.urlImgValidate != null? Colors.green.shade600: Colors.blueAccent.shade400,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.zero,
    );
    int lenEvidence = viewModel.urlImgValidate != null? viewModel.evidenceClosePhotos.length-1:viewModel.evidenceClosePhotos.length;

    String lenEvidencteText = lenEvidence > 0? "[${lenEvidence}/6]":"[${lenEvidence}/6] mínimo 1.";


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
                    header( context,"Cerrar ticket", (){
                      viewModel.disconnectSocket();
                      Navigator.pop(context);
                    } ),
                    const SizedBox(height: 16),
                    textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company!, readOnly: true ),
                    const SizedBox(height: 16),
                    textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
                    const SizedBox(height: 16),
                    textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true, ),
                    const SizedBox(height: 16),
                    textField(viewModel.descriptionCloseController, 'Descripcion', Icons.text_snippet_outlined),
                    const SizedBox(height: 16),
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
                                    await viewModel.takeScreenshotAndSave(true);
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
                          color: viewModel.evidenceClosePhotos.length > 0? Colors.green.shade600: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        )
                    ),
                    EvidenceGrid(
                      images: viewModel.evidenceClosePhotos,
                      onImagesChanged: (images) {
                        setState(() {
                          viewModel.evidenceClosePhotos = images;
                        });
                      },
                      onImageDelete: (_) {
                        setState(() {
                          viewModel.urlImgValidate = null;
                          viewModel.isValidateComponent = false;
                        });
                      },
                      maxImages: 6,
                    ),
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
