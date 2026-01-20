import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../evidence_grid.dart';
import '../text_field_widget.dart';

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
    // Limpiamos las evidencias previas al iniciar la vista
    Future.microtask(() {
      context.read<ListTicketViewmodel>().resetEvidenceStart();
      context.read<ListTicketViewmodel>().initSocket(widget.ticket.unitId, widget.ticket.company!);
    });
  }


  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ListTicketViewmodel>();

    final ButtonStyle styleValidateBtn = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
    );

    return SafeArea(
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
              _header( viewModel ),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company.toString(), readOnly: true ),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true ),
              const SizedBox(height: 10),
              textField(viewModel.descriptionStartController, 'Descripcion', Icons.text_snippet_outlined),
              const SizedBox(height: 10),
              _card(
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
                              // Aquí es donde vinculamos el estado del ViewModel
                              onPressed: viewModel.isDownloadEnabled 
                                ? () {
                                    print("Download pressed");
                                    // Aquí puedes llamar a una función en tu viewModel si la necesitas
                                  } 
                                : null, // Si es null, el botón se deshabilita automáticamente
                              icon: const Icon(Icons.download),
                              label: const Text("Download"),
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
                  text: viewModel.evidencePhotos.length > 0? "[${viewModel.evidencePhotos.length}/6]":"[${viewModel.evidencePhotos.length}/6] mínimo 1.",
                  styles: TextStyle(
                    fontSize: 14,
                    color: viewModel.evidencePhotos.length > 0? Colors.green.shade600: Colors.red.shade600,
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
    );
  }

  Widget _header( ListTicketViewmodel vm ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Iniciar ticket',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => {
            vm.disconnectSocket(),
            Navigator.pop(context)
          },
        )
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

}
