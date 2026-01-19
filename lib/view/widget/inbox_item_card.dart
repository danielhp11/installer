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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isClosed
              ? [Colors.grey.shade200, Colors.grey.shade100]
              : [_getBackgroundColor(), Colors.white], // AQUI CAMBIAR DE COLOR
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
                    _infoText("Ticket #${item.id}"),
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
                    _infoText("Descripción:\n${item.description}"),
                  ],
                ),

                /// 🔹 ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionIcon(
                      icon: Icons.brunch_dining_rounded,
                      visible: !UserSession().isMaster &&
                          item.status == statusOpen,
                      onTap: () =>
                          showStarJobFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.pin_end_sharp,
                      visible: !UserSession().isMaster &&
                          item.status == statusProcess,
                      onTap: () =>
                          showCloseJobFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.security_update_outlined,
                      visible: UserSession().isMaster  &&
                          item.status == statusOpen,
                      onTap: () =>
                          showFuelFormBottomSheet(context, item),
                    ),
                    _actionIcon(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      visible: UserSession().isMaster &&
                          item.status == statusOpen,
                      onTap: () => _showConfirmationDialog(
                        context,
                            () => viewModel.deleteTicket(
                          context: context,
                          idTicket: item.id,
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

  Widget _infoText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
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
        return Colors.blue.shade700;

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
        return Colors.blue.shade50;
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
        return BorderSide(color: Colors.blue.shade200, width: 2);
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
