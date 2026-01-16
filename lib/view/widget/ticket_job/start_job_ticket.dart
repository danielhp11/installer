import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../evidence_grid.dart';

class StartJobTicket extends StatefulWidget {

  final ApiResTicket ticket;

  const StartJobTicket({super.key, required this.ticket});

  @override
  State<StartJobTicket> createState() => _StartJobTicket();
}

class _StartJobTicket extends State<StartJobTicket> {

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
              _textField( label: 'Empresa', icon: Icons.business, value: UserSession().branchRoot, readOnly: true ),
              const SizedBox(height: 16),
              _textField( label: 'Unidad', icon: Icons.bus_alert, value: widget.ticket.unitId, readOnly: true ),
              const SizedBox(height: 16),
              _textField( label: 'Instalador', icon: Icons.person_search_outlined, value: widget.ticket.technicianName, readOnly: true ),
              const SizedBox(height: 16),
              EvidenceGrid(
                images: viewModel.evidencePhotos,
                onImagesChanged: (images) {
                  setState(() {
                    viewModel.evidencePhotos = images;
                  });
                },
                maxImages: 6,
              ),

              ElevatedButton(
                onPressed: () {
                  print("Mandar evidencias de inicio");
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Enviar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _textField({
    required String label,
    required IconData icon,
    required String value,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: TextEditingController(text: value),
      readOnly: readOnly,
      onTap: onTap, // para manejar clicks si quieres
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (!readOnly && (v == null || v.isEmpty)) {
          return 'Campo requerido';
        }
        return null;
      },
    );
  }


}