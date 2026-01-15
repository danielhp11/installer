import 'package:flutter/material.dart';
import 'package:instaladores_new/service/request_service.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:provider/provider.dart';

import '../../service/response_service.dart';
import '../../viewModel/list_ticket_viewmodel.dart';
import 'bottom_sheet_utils.dart';

class InboxItemCard extends StatelessWidget {
  final ApiResTicket item;
  // final VoidCallback onTap;

  static const String statusOpen = "ABIERTO";
  static const String statusProcess = "PROCESO";
  static const String statusPendingValidation = "PENDIENTE_VALIDACION";
  static const String statusFinished = "FINALIZADO";
  static const String statusClosed = "CANCELADO";



  const InboxItemCard({
    super.key,
    required this.item,
    // required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClosed = item.status == "CERRADO";
    final viewModel = context.watch<ListTicketViewmodel>();


    return Card(
      elevation: isClosed ? 1 : 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _getBorderSide(),
      ),
      color: _getBackgroundColor(),
      child: InkWell(
        // onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Company and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.unitId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const Divider(height: 16),

              // Unit name and ticket number
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: isClosed ? Colors.grey.shade400 : Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.unitId,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isClosed ? Colors.grey.shade600 : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: 150, // ancho fijo en píxeles que quieras
                    child: Text(
                      'Ticket #${item.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Technician Name
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.technicianName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Spacer(),
                      _iconOption(
                        icon: Icons.brunch_dining_rounded,
                        onPressed: () => print("=> Init job"),
                        visible: !UserSession().isMaster && item.status != statusClosed,
                      ),
                      _iconOption(
                        icon: Icons.pin_end_sharp,
                        onPressed: () =>print("=> closed job"),
                        visible: !UserSession().isMaster && item.status != statusClosed,
                      ),
                      _iconOption(
                        icon: Icons.security_update_outlined,
                        onPressed: () => showFuelFormBottomSheet(context, item),
                        visible: UserSession().isMaster && item.status != statusClosed,
                      ),
                      _iconOption(
                        icon: Icons.delete,
                        onPressed: () => _showConfirmationDialog(context, ()=> viewModel.deleteTicket(context: context, idTicket: item.id) ),
                        visible: UserSession().isMaster && item.status != statusClosed,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBadgeColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.status, // Corregido: Mostrar status en lugar de unitId
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconOption({
    required IconData icon,
    required VoidCallback onPressed,
    bool visible = true, // Por defecto es visible
  }) {
    if (!visible) return const SizedBox.shrink(); // Si no es visible, no ocupa espacio

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }


  Color _getBadgeColor() {
    switch (item.status.toUpperCase()) {
      case statusOpen:
        return Colors.yellow.shade700;

      case statusProcess:
        return Colors.orange.shade700;

      // case statusPendingValidation:
      //   return Colors.purple.shade700;

      case statusFinished:
        return Colors.green.shade700;

      case statusClosed:
        return Colors.grey.shade600;

      default:
        return Colors.blueGrey;
    }
  }

  Color _getBackgroundColor() {
    switch (item.status) {
      case statusOpen:
        return Colors.red.shade50;
      case statusProcess:
        return Colors.orange.shade50;
      // case "enRevision":
      //   return Colors.purple.shade50;
      case statusFinished:
        return Colors.green.shade50;
      case statusClosed:
        return Colors.grey.shade100;
      default:
        return Colors.white;
    }
  }

  BorderSide _getBorderSide() {
    switch (item.status) {
      case statusOpen:
        return BorderSide(color: Colors.red.shade200, width: 2);
      case statusProcess:
        return BorderSide(color: Colors.orange.shade200, width: 2);
      // case "enRevision":
      //   return BorderSide(color: Colors.purple.shade200, width: 2);
      case statusFinished:
        return BorderSide(color: Colors.green.shade200, width: 1);
      case statusClosed:
        return BorderSide(color: Colors.grey.shade300, width: 1);
      default:
        return const BorderSide(color: Colors.transparent);
    }
  }

  void _showConfirmationDialog(
      BuildContext context,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Eliminar!'),
          content: const Text('¿Deseas eliminar permanentemente?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                onConfirm();
                // Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
