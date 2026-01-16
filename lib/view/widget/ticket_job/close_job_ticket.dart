import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instaladores_new/service/response_service.dart';
import 'package:provider/provider.dart';

import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../evidence_grid.dart';

class CloseJobTicket extends StatefulWidget {

  final ApiResTicket ticket;

  const CloseJobTicket({super.key, required this.ticket});

  @override
  State<CloseJobTicket> createState() => _CloseJobTicket();
}
class _CloseJobTicket extends State<CloseJobTicket> {


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
          'Cerrar ticket',
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