import 'package:flutter/material.dart';
import 'package:instaladores_new/service/request_service.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/widget/card_widget.dart';
import 'package:instaladores_new/widget/text_field_widget.dart';
import 'package:provider/provider.dart';

import '../service/response_service.dart';
import '../viewModel/evidence_start_finish_viewmodel.dart';
import '../viewModel/list_ticket_viewmodel.dart';
import 'bottom_sheet_utils.dart';
import 'evidence_gallery.dart';

class InboxItemCard extends StatefulWidget {
  final ApiResTicket item;

  static const String statusOpen = "ABIERTO";
  static const String statusProcess = "PROCESO";
  static const String statusPendingValidation = "PENDIENTE_VALIDACION";
  static const String statusClosed = "CERRADO";
  static const String statusCancel = "CANCELADO";

  const InboxItemCard({
    super.key,
    required this.item,
  });

  @override
  State<InboxItemCard> createState() => _InboxItemCardState();
}

class _InboxItemCardState extends State<InboxItemCard> {
  List<ItemEvidence> evidenceStart = [];
  List<ItemEvidence> evidenceClose = [];

  @override
  void initState() {
    super.initState();
    _separateEvidence();
  }

  @override
  void didUpdateWidget(covariant InboxItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.evidences != widget.item.evidences) {
      _separateEvidence();
    }
  }

  void _separateEvidence() {
    evidenceStart = widget.item.evidences
        .where((e) => e.phase.toUpperCase() == "PROCESO")
        .toList();
    evidenceClose = widget.item.evidences
        .where((e) => e.phase.toUpperCase() != "PROCESO")
        .toList();

    if (RequestServ.isDebug) {
      print("<=================================================================================================================================>");
      print("EVIDENCE TICKET => ${widget.item.id}");
      print("EVIDENCE START => ${evidenceStart.length}");
      print("EVIDENCE CLOSE => ${evidenceClose.length}");
      print("<=================================================================================================================================>");
    }
  }

  String formatDateManual(String isoDate) {
    final DateTime d = DateTime.parse(isoDate);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year.toString().substring(2)}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = widget.item.status == "CERRADO";
    final bool isCancel = widget.item.status == "CANCELADO";
    final viewModel = context.watch<ListTicketViewmodel>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getBadgeColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: _getBadgeColor(),
            width: 5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  _getBackgroundColor().withOpacity(0.3),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER - Unit ID & Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getBadgeColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 24,
                        color: _getBadgeColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.unitId,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isClosed ? Colors.grey.shade600 : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ticket #${widget.item.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 12),

                /// INFO CHIPS
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      Icons.calendar_today_rounded,
                      formatDateManual(widget.item.create_at!),
                    ),
                    _infoChip(
                      Icons.person_rounded,
                      widget.item.technicianName,
                    ),
                    _infoChip(
                      Icons.business_rounded,
                      widget.item.company ?? 'N/A',
                    ),
                  ],
                ),

                if (widget.item.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isCancel && widget.item.history?.last.notes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.history!.last.notes ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                /// ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionIcon(
                      icon: Icons.play_circle_outline_rounded,
                      color: Colors.green.shade700,
                      visible: !UserSession().isMaster && widget.item.status == InboxItemCard.statusOpen,
                      onTap: () => showStarJobFormBottomSheet(context, widget.item),
                    ),
                    _actionIcon(
                      icon: Icons.task_alt_rounded,
                      color: Colors.orange.shade700,
                      visible: !UserSession().isMaster && widget.item.status == InboxItemCard.statusProcess,
                      onTap: () => showCloseJobFormBottomSheet(context, widget.item),
                    ),
                    _actionIcon(
                      icon: Icons.edit_rounded,
                      visible: UserSession().isMaster && widget.item.status == InboxItemCard.statusOpen,
                      onTap: () => showFuelFormBottomSheet(context, widget.item),
                    ),
                    _actionIcon(
                      icon: Icons.delete_rounded,
                      color: Colors.redAccent,
                      visible: UserSession().isMaster && widget.item.status == InboxItemCard.statusOpen,
                      onTap: () => _showConfirmationDialog(
                        context,
                        (reason) => viewModel.deleteTicket(
                          context: context,
                          idTicket: widget.item.id,
                          reason: reason,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (widget.item.evidences.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textFieldOnlyRead(
                        label: "EVIDENCIAS",
                        icon: Icons.photo_camera,
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                evidenceStart.length > 0?
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: _evidenceButton(
                                          "INICIO ${evidenceStart.length}",
                                          onTap: () {
                                            _openEvidenceModal(
                                              context: context,
                                              title: "Evidencia Inicial",
                                              evidence: evidenceStart,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                                evidenceClose.length > 0?
                                    Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: _evidenceButton(
                                      "CIERRE ${evidenceClose.length}",
                                      onTap: () {
                                        _openEvidenceModal(
                                          context: context,
                                          title: "Evidencia Cierre",
                                          evidence: evidenceClose,
                                        );
                                      },
                                    ),
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEvidenceModal({
    required BuildContext context,
    required String title,
    required List<ItemEvidence> evidence,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EvidenceGallery(
        title: title,
        evidence: evidence,
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final Color color = _getBadgeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.item.status,
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

  Widget _evidenceButton(String text, {required VoidCallback onTap}) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF7FA8A4), Color(0xFF6C8EA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  size: 15,
                  color: Colors.white.withOpacity(0.95),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (widget.item.status.toUpperCase()) {
      case InboxItemCard.statusProcess:
        return Colors.orange.shade700;
      case InboxItemCard.statusPendingValidation:
        return Colors.deepPurple.shade700;
      case InboxItemCard.statusClosed:
        return Colors.lightGreen.shade700;
      case InboxItemCard.statusCancel:
        return Colors.grey.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.item.status) {
      case InboxItemCard.statusProcess:
        return Colors.orange.shade50;
      case InboxItemCard.statusPendingValidation:
        return Colors.deepPurple.shade50;
      case InboxItemCard.statusClosed:
        return Colors.lightGreen.shade50;
      case InboxItemCard.statusCancel:
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
