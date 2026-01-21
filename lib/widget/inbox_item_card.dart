import 'package:flutter/material.dart';
import 'package:instaladores_new/service/request_service.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/widget/text_field_widget.dart';
import 'package:provider/provider.dart';

import '../service/response_service.dart';
import '../viewModel/list_ticket_viewmodel.dart';
import 'bottom_sheet_utils.dart';

class InboxItemCard extends StatelessWidget {
  final ApiResTicket item;
  // final VoidCallback onTap;

  static const String statusOpen = "ABIERTO";
  static const String statusProcess = "PROCESO";
  static const String statusPendingValidation = "PENDIENTE_VALIDACION";
  static const String statusClosed = "CERRADO";
  static const String statusCancel = "CANCELADO";



  const InboxItemCard({
    super.key,
    required this.item,
    // required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClosed = item.status == "CERRADO";
    final bool isCancel = item.status == "CANCELADO";
    final viewModel = context.watch<ListTicketViewmodel>();
    // print("=> InboxItemCard: ${item.history?.last.notes}");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isClosed
              ? [_getBackgroundColor(), Colors.grey.shade100]
              : [_getBackgroundColor(), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 HEADER
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 28,
                      color: isClosed
                          ? Colors.grey
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        item.unitId,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isClosed
                              ? Colors.grey.shade700
                              : Colors.black87,
                        ),
                      ),
                    ),

                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),

                /// 🔹 SUBINFO
                Row(
                  children: [
                    infoText(text: "Ticket #${item.id}"),
                    const Spacer(),
                    Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.technicianName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoText(text: "Empresa: ${item.company}"),
                    const SizedBox(height: 16),
                    infoText(text: "Descripción:\n${item.description}"),
                    const SizedBox(height: 16),
                    isCancel? infoText(text: "${item.history?.last.notes}"):SizedBox.shrink(),
                  ],
                ),

                /// 🔹 ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionIcon(
                      icon: Icons.construction,
                      color: _getBadgeColor(),
                      visible: !UserSession().isMaster &&
                          item.status == statusOpen,
                      onTap: () =>
                          showStarJobFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.task_alt,
                      color: _getBadgeColor(),
                      visible: !UserSession().isMaster &&
                          item.status == statusProcess,
                      onTap: () =>
                          showCloseJobFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.edit,
                      visible: UserSession().isMaster  &&
                          item.status == statusOpen,
                      onTap: () =>
                          showFuelFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.delete_forever,
                      color: Colors.redAccent,
                      visible: UserSession().isMaster &&
                          item.status == statusOpen,
                      onTap: () => _showConfirmationDialog(
                        context,
                        (reason) => viewModel.deleteTicket(
                          context: context,
                          idTicket: item.id,
                          reason: reason,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final Color color = _getBadgeColor();
    // final Color color = item.status == "CERRADO"
    //     ? Colors.grey
    //     : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required bool visible,
    Color color = Colors.blue,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (item.status.toUpperCase()) {
      case statusProcess:
        return Colors.orange.shade700;

      case statusPendingValidation:
        return Colors.deepPurple.shade700;

      case statusClosed:
        return Colors.lightGreen.shade700;

      case statusCancel:
        return Colors.grey.shade700;

      default:
        return Colors.blue.shade700;
    }
  }

  Color _getBackgroundColor() {
    switch (item.status) {
      case statusProcess:
        return Colors.orange.shade50;

      case statusPendingValidation:
        return Colors.deepPurple.shade50;

      case statusClosed:
        return Colors.lightGreen.shade50;

      case statusCancel:
        return Colors.grey.shade50;

      default:
        return Colors.blue.shade50;
    }
  }

  void _showConfirmationDialog(
      BuildContext context,
      Function(String) onConfirm,
      ) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Eliminar!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Deseas eliminar permanentemente?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de cancelación',
                  hintText: 'Escribe aquí el motivo (mín. 5 caract.)...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: reasonController,
              builder: (context, value, child) {
                final bool isValid = value.text.trim().length >= 5;
                return TextButton(
                  onPressed: isValid
                      ? () {
                    onConfirm(reasonController.text.trim());
                  }
                      : null,
                  child: Text(
                    'Aceptar',
                    style: TextStyle(
                      color: isValid ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

}
