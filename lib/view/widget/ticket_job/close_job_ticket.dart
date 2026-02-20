import 'dart:async';
import 'package:flutter/material.dart';
import 'package:instaladores_new/service/response_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/text_field_widget.dart';
import '../../../widget/maps_widget.dart';

class CloseJobTicket extends StatefulWidget {
  final ApiResTicket ticket;

  const CloseJobTicket({super.key, required this.ticket});

  @override
  State<CloseJobTicket> createState() => _CloseJobTicketState();
}

class _CloseJobTicketState extends State<CloseJobTicket> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // PageController con IndexedStack para no desmontar el mapa al navegar
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ListTicketViewmodel>().isLoadingClose = true;
      context.read<ListTicketViewmodel>().resetEvidenceClose();
      context.read<ListTicketViewmodel>().initSocket(
            widget.ticket.unitId.toString(),
            widget.ticket.company.toString(),
          );
      context.read<ListTicketViewmodel>().isLoadingClose = false;
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
    // Si estamos en el paso 1, verificar que todos los no-idle estén aprobados
    if (_currentStep == 0) {
      final vm = context.read<ListTicketViewmodel>();
      if (!vm.allSelectedComponentsApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Faltan componentes por validar u obtener aprobación del administrador.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return; // No avanzar
      }
    }
    if (_currentStep < _totalSteps - 1) _goToStep(_currentStep + 1);
  }

  void _prev() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListTicketViewmodel>();

    return Screenshot(
      controller: viewModel.screenshotCloseController,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Form(
            key: viewModel.formKeyCloseJob,
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
                      _Step1ModeloComponentes(
                        viewModel: viewModel,
                        ticket: widget.ticket,
                      ),
                      _Step2ValidacionMapa(
                        viewModel: viewModel,
                        ticket: widget.ticket,
                      ),
                      _Step3EvidenciasComentario(
                        viewModel: viewModel,
                        onImagesChanged: (List<Map<String, String>> imgs) =>
                            setState(() => viewModel.evidenceClosePhotos = imgs),
                        onImageDelete: (Map<String, String> item) {
                          setState(() {
                            if (item['source'] == 'SCREENSHOT_COMPONENTS') {
                              viewModel.urlImgComponent = null;
                              viewModel.isValidateComponent = false;
                            } else if (item['source'] == 'SCREENSHOT_MAPS') {
                              viewModel.urlImgMaps = null;
                              viewModel.isEvidenceUnitUserClose = false;
                            }
                          });
                        },
                      ),
                      _Step4Resumen(
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
                  onSend: () => viewModel.sendEvidenceClose(
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
// Header fijo
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
          // Ícono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment_turned_in_rounded,
                color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Datos del trabajo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cerrar Trabajo',
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
          // Cerrar
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

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step indicator
// ════════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  static const _labels = ['Modelo', 'Validación', 'Evidencias', 'Resumen'];

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
            child: Row(
              children: [
                // Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 28 : 22,
                  height: isActive ? 28 : 22,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade500
                        : isActive
                            ? primary
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                // Label (solo activo)
                if (isActive)
                  Flexible(
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Conector
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
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

// ════════════════════════════════════════════════════════════════════════════
// Barra de navegación inferior
// ════════════════════════════════════════════════════════════════════════════

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
          // Botón anterior
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
          // Botón siguiente / enviar
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
              label: const Text('Enviar'),
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

// ════════════════════════════════════════════════════════════════════════════
// PASO 1 — Modelo de unidad + evidencias de componentes
// ════════════════════════════════════════════════════════════════════════════

class _Step1ModeloComponentes extends StatefulWidget {
  final ListTicketViewmodel viewModel;
  final ApiResTicket ticket;

  const _Step1ModeloComponentes({
    required this.viewModel,
    required this.ticket,
  });

  @override
  State<_Step1ModeloComponentes> createState() =>
      _Step1ModeloComponentesState();
}

class _Step1ModeloComponentesState extends State<_Step1ModeloComponentes> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Iniciar polling de validación de componentes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Usamos el ticketId que nos pasan desde el widget parent
      context
          .read<ListTicketViewmodel>()
          .pollComponentStatuses(widget.ticket.id.toString());
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Modelo de unidad ──────────────────────────────────────────────
          _SectionCard(
            icon: Icons.directions_bus_filled_rounded,
            iconColor: Colors.blue,
            title: 'Modelo de Unidad',
            child: textField(
              vm.unitModelCloseController,
              'Modelo de unidad (*)',
              Icons.text_snippet_outlined,
            ),
          ),

          const SizedBox(height: 16),

          // ── Evidencias de componentes ─────────────────────────────────────
          _SectionCard(
            icon: Icons.electrical_services_rounded,
            iconColor: Colors.purple,
            title: 'Evidencias de Componentes',
            subtitle: 'Toca cada componente para agregar su evidencia.',
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.purple),
              onPressed: () {
                vm.pollComponentStatuses(widget.ticket.id.toString());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualizando estados...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ComponentButton(
                      label: 'VCC',
                      status: vm.componentStatuses['VCC'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'VCC', widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'GNC',
                      status: vm.componentStatuses['GND'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'GND', widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'IGNICIÓN',
                      status:
                          vm.componentStatuses['IGNITION'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'IGNITION', widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'GPS',
                      status: vm.componentStatuses['GPS'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'GPS', widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'ARMADO',
                      status: vm.componentStatuses['UNIT_ASSEMBLY'] ??
                          ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap('UNIT_ASSEMBLY',
                          widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'EXTRA 1',
                      status:
                          vm.componentStatuses['p_extra1'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'p_extra1', widget.ticket.id.toString(), context),
                    ),
                    _ComponentButton(
                      label: 'EXTRA 2',
                      status:
                          vm.componentStatuses['p_extra2'] ?? ComponentStatus.idle,
                      onTap: () => vm.handleComponentTap(
                          'p_extra2', widget.ticket.id.toString(), context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Botón de componente individual ─────────────────────────────────────────────
class _ComponentButton extends StatelessWidget {
  final String label;
  final ComponentStatus status;
  final VoidCallback onTap;

  const _ComponentButton({
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? iconData;
    Color iconColor;
    bool isUploading = false;

    switch (status) {
      case ComponentStatus.idle:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        iconData = Icons.radio_button_unchecked_rounded;
        iconColor = Colors.grey.shade500;
        break;
      case ComponentStatus.selected:
        bgColor = Colors.yellow.shade50;
        borderColor = Colors.yellow.shade400;
        textColor = Colors.orange.shade800;
        iconData = Icons.camera_alt_outlined;
        iconColor = Colors.orange.shade600;
        break;
      case ComponentStatus.uploading:
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        textColor = Colors.blue.shade800;
        isUploading = true;
        iconColor = Colors.blue.shade600;
        break;
      case ComponentStatus.pending:
        bgColor = Colors.blue.shade100;
        borderColor = Colors.blue.shade400;
        textColor = Colors.blue.shade900;
        iconData = Icons.hourglass_top_rounded;
        iconColor = Colors.blue.shade700;
        break;
      case ComponentStatus.approved:
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade400;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.green.shade600;
        break;
      case ComponentStatus.rejected:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade400;
        textColor = Colors.red.shade800;
        iconData = Icons.cancel_rounded;
        iconColor = Colors.red.shade600;
        break;
    }

    return InkWell(
      onTap: status == ComponentStatus.uploading || status == ComponentStatus.pending
          ? null
          : onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUploading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            else
              Icon(iconData, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PASO 2 — Validación de funciones + Mapa
// ════════════════════════════════════════════════════════════════════════════

class _Step2ValidacionMapa extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final ApiResTicket ticket;

  const _Step2ValidacionMapa({
    required this.viewModel,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;

    final ButtonStyle screenshotBtn = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
      backgroundColor:
          vm.isValidateComponent && vm.urlImgComponent != null
              ? Colors.green.shade600
              : Colors.blueAccent.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: EdgeInsets.zero,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Validación de funciones ───────────────────────────────────────
          _SectionCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.blue.shade700,
            title: 'Validación de Funciones',
            child: Column(
              children: [
                // Fila captura de validación
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Valida la función',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            vm.isDownloadEnabled && vm.urlImgComponent == null
                                ? () async {
                                    await vm.takeScreenshotAndSave(true);
                                    if (context.mounted &&
                                        vm.urlImgComponent != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Evidencia capturada con éxito'),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                        icon: Icon(vm.isValidateComponent
                            ? Icons.check_circle
                            : Icons.camera_alt),
                        label: Text(vm.isValidateComponent
                            ? 'Evidencia lista'
                            : 'Tomar evidencia'),
                        style: screenshotBtn,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Lectoras
                _FunctionRow(
                  label: 'Lectoras',
                  controller: vm.lectorasController,
                ),

                const SizedBox(height: 10),

                // Botón de pánico
                _FunctionRow(
                  label: 'Botón de pánico',
                  controller: vm.panicoController,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Mapa ──────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.map_rounded,
            iconColor: Colors.green.shade700,
            title: 'Ubicación de la Unidad',
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 420,
                  child: CustomGoogleMap(
                    deviceId: ticket.unitId,
                    isTicketClose: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunctionRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _FunctionRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 3,
          child: TextFormField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PASO 3 — Evidencias después de terminar + Comentario
// ════════════════════════════════════════════════════════════════════════════

class _Step3EvidenciasComentario extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final void Function(List<Map<String, String>>) onImagesChanged;
  final void Function(Map<String, String>) onImageDelete;

  const _Step3EvidenciasComentario({
    required this.viewModel,
    required this.onImagesChanged,
    required this.onImageDelete,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final int lenEvidence = vm.evidenceClosePhotos
        .where((img) =>
            img['source'] != 'SCREENSHOT_COMPONENTS' &&
            img['source'] != 'SCREENSHOT_MAPS')
        .length;

    final String evidenceText = '[$lenEvidence/6] mínimo 1.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Evidencias ────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.photo_library_rounded,
            iconColor: Colors.orange.shade700,
            title: 'Evidencia Después de Terminar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                infoText(
                  text: evidenceText,
                  styles: TextStyle(
                    fontSize: 13,
                    color: lenEvidence > 0
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                EvidenceGrid(
                  images: vm.evidenceClosePhotos,
                  onImagesChanged: onImagesChanged,
                  onImageDelete: onImageDelete,
                  maxImages: 8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Comentario ────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.comment_rounded,
            iconColor: Colors.teal,
            title: 'Comentario de Revisión',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: textField(
                vm.descriptionCloseController,
                'Comentario de revisión (*)',
                Icons.text_snippet_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PASO 4 — Resumen del trabajo
// ════════════════════════════════════════════════════════════════════════════

class _Step4Resumen extends StatelessWidget {
  final ListTicketViewmodel viewModel;
  final ApiResTicket ticket;

  const _Step4Resumen({
    required this.viewModel,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;

    final int totalFotos = vm.evidenceClosePhotos
        .where((img) =>
            img['source'] != 'SCREENSHOT_COMPONENTS' &&
            img['source'] != 'SCREENSHOT_MAPS')
        .length;

    // Componentes validados (APPROVED)
    final components = ['VCC', 'GND', 'IGNITION', 'GPS', 'UNIT_ASSEMBLY', 'p_extra1', 'p_extra2'];
    final int compDone = vm.componentStatuses.values
        .where((s) => s == ComponentStatus.approved)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Resumen superior ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.directions_bus_filled_rounded,
                  label: 'Unidad',
                  value: ticket.unitId,
                ),
                _SummaryRow(
                  icon: Icons.text_snippet_outlined,
                  label: 'Modelo',
                  value: vm.unitModelCloseController.text.isEmpty
                      ? 'N/A'
                      : vm.unitModelCloseController.text,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Tarjetas de métricas ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.collections_rounded,
                  color: Colors.blue,
                  label: 'Fotos',
                  value: '${vm.evidenceClosePhotos.length}',
                  sub: 'adjuntas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.electrical_services_rounded,
                  color: Colors.purple,
                  label: 'Componentes',
                  value: '$compDone/${components.length}',
                  sub: 'validados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.teal,
                  label: 'Validación',
                  value: vm.isValidateComponent ? '✓' : '—',
                  sub: 'capturada',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Comentario de revisión ────────────────────────────────────────
          _SectionCard(
            icon: Icons.comment_rounded,
            iconColor: Colors.teal,
            title: 'Comentario de Revisión',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                vm.descriptionCloseController.text.isEmpty
                    ? '—'
                    : vm.descriptionCloseController.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared: tarjeta de sección con encabezado consistente
// ════════════════════════════════════════════════════════════════════════════

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
