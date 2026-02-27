import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/card_widget.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/header_widget.dart';
import '../../../widget/maps_widget.dart';
import '../../../widget/text_field_widget.dart';

class StartJobTicket extends StatefulWidget {
  final ApiResTicket ticket;

  const StartJobTicket({super.key, required this.ticket});

  @override
  State<StartJobTicket> createState() => _StartJobTicketState();
}

class _StartJobTicketState extends State<StartJobTicket> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      context.read<ListTicketViewmodel>().isLoadingStart = true;
      context.read<ListTicketViewmodel>().resetEvidenceStart();
      context.read<ListTicketViewmodel>().isLoadingStart = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) _goToStep(_currentStep + 1);
  }

  void _prev() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListTicketViewmodel>();

    if (viewModel.isLoadingStart) {
      return const Center(child: CircularProgressIndicator());
    }

    return Screenshot(
      controller: viewModel.screenshotController,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Form(
            key: viewModel.formKeyStartJob,
            child: Column(
              children: [
                // ─── Header fijo ────────────────────────────────────────────
                _FixedHeader(
                  ticket: widget.ticket,
                  onClose: () {
                    viewModel.disconnectSocket();
                    Navigator.pop(context);
                  },
                ),

                // ─── Step indicator ─────────────────────────────────────────
                _StepIndicator(current: _currentStep, total: _totalSteps),

                // ─── Contenido paginado ──────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _Step1ValidacionMapa(
                        viewModel: viewModel,
                        ticket: widget.ticket,
                      ),
                      _Step2EvidenciasComentario(
                        viewModel: viewModel,
                        onImagesChanged: (List<Map<String, String>> imgs) =>
                            setState(() => viewModel.evidencePhotos = imgs),
                        onImageDelete: (Map<String, String> item) {
                          setState(() {
                            if (item['source'] == 'SCREENSHOT_COMPONENTS') {
                              viewModel.urlImgComponent = null;
                              viewModel.isValidateComponent = false;
                            } else if (item['source'] == 'SCREENSHOT_MAPS') {
                              viewModel.urlImgMaps = null;
                              viewModel.isEvidenceUnitUserStart = false;
                            }
                          });
                        },
                      ),
                      _Step3Resumen(
                        viewModel: viewModel,
                        ticket: widget.ticket,
                      ),
                    ],
                  ),
                ),

                // ─── Navegación inferior ────────────────────────────────────
                _NavBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onPrev: _prev,
                  onNext: _next,
                  onSend: () => viewModel.sendEvidence(
                    context: context,
                    idTicket: widget.ticket.id,
                    ticket: widget.ticket,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Componentes compartidos y Pasos (Diseño similar a CloseJobTicket)
// ════════════════════════════════════════════════════════════════════════════

class _FixedHeader extends StatelessWidget {
  final ApiResTicket ticket;
  final VoidCallback onClose;

  const _FixedHeader({required this.ticket, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Iniciar Trabajo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    _Chip(
                      icon: Icons.business_rounded,
                      label: ticket.company ?? '-',
                      color: Colors.indigo,
                    ),
                    _Chip(
                      icon: Icons.directions_bus_rounded,
                      label: ticket.unitId,
                      color: Colors.teal,
                    ),
                    _Chip(
                      icon: Icons.person_rounded,
                      label: ticket.technicianName,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  static const _labels = ['Validación', 'Evidencias', 'Resumen'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade50,
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i == current;
          final isDone = i < current;

          return Expanded(
            flex: isActive ? 2 : 1,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 24 : 18,
                  height: isActive ? 24 : 18,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade500
                        : isActive
                            ? primary
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: i < current
                          ? Colors.green.shade400
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSend;

  const _NavBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onPrev,
    required this.onNext,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = currentStep == 0;
    final isLast = currentStep == totalSteps - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const Spacer(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: onNext,
              icon: const Text('Siguiente'),
              label: const Icon(Icons.chevron_right_rounded),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Iniciar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step1ValidacionMapa extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final ApiResTicket ticket;

  const _Step1ValidacionMapa({required this.viewModel, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.blue.shade700,
            title: 'Validación y Ubicación',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ValidationRow(label: 'Validación de corriente'),
                const SizedBox(height: 10),
                _ValidationRow(label: 'Validación de tierra'),
                const SizedBox(height: 10),
                _ValidationRow(label: 'Validación de ignición'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 400,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomGoogleMap(
                      deviceId: ticket.unitId,
                      isTicketClose: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  final String label;

  const _ValidationRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _Step2EvidenciasComentario extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final Function(List<Map<String, String>>) onImagesChanged;
  final Function(Map<String, String>) onImageDelete;

  const _Step2EvidenciasComentario({
    required this.viewModel,
    required this.onImagesChanged,
    required this.onImageDelete,
  });

  @override
  Widget build(BuildContext context) {
    int lenEvidence = viewModel.evidencePhotos
        .where((img) =>
            img['source'] != 'SCREENSHOT_COMPONENTS' &&
            img['source'] != 'SCREENSHOT_MAPS')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            icon: Icons.camera_alt_rounded,
            iconColor: Colors.green.shade700,
            title: 'Evidencia Antes de Iniciar',
            subtitle: '[$lenEvidence/6] mínimo 1.',
            child: EvidenceGrid(
              images: viewModel.evidencePhotos,
              onImagesChanged: (images) => onImagesChanged(images),
              onImageDelete: (item) => onImageDelete(item),
              maxImages: 8,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.comment_rounded,
            iconColor: Colors.orange.shade700,
            title: 'Descripción / Comentarios',
            child: textField(
              viewModel.descriptionStartController,
              'Ingresa una descripción opcional...',
              Icons.text_snippet_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Resumen extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final ApiResTicket ticket;

  const _Step3Resumen({required this.viewModel, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            icon: Icons.summarize_rounded,
            iconColor: Colors.indigo.shade700,
            title: 'Resumen de Inicio',
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.business,
                  label: 'Empresa',
                  value: ticket.company ?? '-',
                ),
                _SummaryRow(
                  icon: Icons.bus_alert,
                  label: 'Unidad',
                  value: ticket.unitId,
                ),
                _SummaryRow(
                  icon: Icons.camera_alt,
                  label: 'Evidencias',
                  value: '${viewModel.evidencePhotos.length} capturadas',
                ),
                if (viewModel.descriptionStartController.text.isNotEmpty)
                  _SummaryRow(
                    icon: Icons.comment,
                    label: 'Comentario',
                    value: viewModel.descriptionStartController.text,
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Al presionar "Iniciar", se registrará el comienzo del trabajo con la información proporcionada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

