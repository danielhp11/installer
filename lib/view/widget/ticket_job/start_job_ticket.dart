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
    });
  }

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ListTicketViewmodel>();

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
              _header(),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Empresa', icon: Icons.business, value: widget.ticket.company.toString(), readOnly: true ),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
              const SizedBox(height: 16),
              textFieldOnlyRead( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true ),
              const SizedBox(height: 10),
              textField(viewModel.descriptionStartController, 'Descripcion', Icons.text_snippet_outlined),
              const SizedBox(height: 10),
              infoText("[${viewModel.evidencePhotos.length}/6] mínimo 1."),
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

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Iniciar ticket',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

}
