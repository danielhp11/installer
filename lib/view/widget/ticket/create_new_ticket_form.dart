import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../../../widget/header_widget.dart';
import '../../../widget/maps_widget.dart';
import '../../../widget/selector_field.dart';
import '../../../widget/text_field_widget.dart';
import '../../../widget/evidence_grid.dart';
import '../../../widget/card_widget.dart';

class CreateNewTicketForm extends StatefulWidget {

  final ApiResTicket? ticket;

  const CreateNewTicketForm({super.key, required this.ticket});

  @override
  State<CreateNewTicketForm> createState() => _CreateNewTicketForm();

}

class _CreateNewTicketForm extends State<CreateNewTicketForm> {

  bool isUpdate = false;


  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final vm = context.read<ListTicketViewmodel>();

    vm.isLoadNewUpdate = true;
    vm.getInstaller();
    vm.resetEvidenceStart();
    vm.resetEvidenceClose();

    await vm.loadExternalUnits(UserSession().branchRoot);

    if (widget.ticket != null) {

      if (mounted) {
        vm.companyController.text = widget.ticket!.company ?? '';
        vm.installerController.text = widget.ticket!.technicianName;

        vm.unitController.text = widget.ticket!.unitId;
        vm.descriptionController.text = widget.ticket!.description;
        vm.selectedUnitId = widget.ticket!.unitId.toString() != "null"?  int.parse(widget.ticket!.unitId):0;

        if (vm.units.contains(widget.ticket!.unitId)) {
          vm.setSelectedUnit(unit : widget.ticket!.unitId, company: widget.ticket!.company!, isInit: true);
        }
        setState(() {
          isUpdate = true;
        });

      }
    } else {

      if (mounted) {
        vm.resetForm();

        vm.companyController.text = UserSession().branchRoot;
        if(!UserSession().isMaster){
          vm.installerId = UserSession().idUser;
          vm.installerController.text = UserSession().nameUser;

        }

        setState(() {
          isUpdate = false;
        });
      }
    }
    vm.isLoadNewUpdate = false;
  }

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ListTicketViewmodel>();

    if (viewModel.isLoadNewUpdate) return const Center(child: CircularProgressIndicator());

    String textTitle = isUpdate ? 'Actualizar revisión' : 'Revisión de unidad';

    final ButtonStyle styleValidateBtn = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
      backgroundColor: viewModel.isValidateComponent && viewModel.urlImgComponent != null? Colors.green.shade600: Colors.blueAccent.shade400,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.zero,
    );

    return Screenshot(
      controller: viewModel.screenshotCloseController,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: viewModel.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header(
                    context,
                    textTitle,
                    () {
                      viewModel.disconnectSocket();
                      Navigator.pop(context);
                    }
                  ),
                  const SizedBox(height: 20),
                  
                  /// BASIC INFO SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Información de la Revisión',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _branchField(viewModel),
                        const SizedBox(height: 16),
                        UserSession().isMaster ?
                        _installerField(viewModel):
                        textFieldOnlyRead(
                          label: 'Instalador',
                          icon: Icons.person_search_outlined,
                          value: UserSession().nameUser,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _unitField(viewModel),
                        const SizedBox(height: 16),
                        textField(viewModel.unitModelCloseController, 'Modelo de unidad', Icons.directions_bus_filled_outlined),
                        const SizedBox(height: 16),
                        textField(viewModel.descriptionController, 'Comentarios de revisión', Icons.text_snippet_outlined),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// VALIDATION SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.blue.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Validación y Ubicación',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: textFieldOnlyRead( label: '', icon: Icons.assignment_turned_in, value: "Valida la función", readOnly: true ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: viewModel.isDownloadEnabled && viewModel.urlImgComponent == null
                                    ? () async {
                                  await viewModel.takeScreenshotAndSave(true);
                                  if (mounted && viewModel.urlImgComponent != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Evidencia capturada con éxito')),
                                    );
                                  }
                                }
                                    : null,
                                icon: Icon(viewModel.isValidateComponent ? Icons.check_circle : Icons.camera_alt),
                                label: Text(viewModel.isValidateComponent ? "Evidencia lista" : "Tomar evidencia"),
                                style: styleValidateBtn,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              flex: 2,
                              child:  Text(
                                  "Lectoras",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              flex: 3,
                              child: TextFormField(
                                controller: viewModel.lectorasController,
                                readOnly: true,
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  labelText: "Estado",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                                flex: 2,
                                child: Text(
                                    "Botón de pánico",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                )
                            ),

                            const SizedBox(width: 10),
                            Flexible(
                              flex: 3,
                              child: TextFormField(
                                controller: viewModel.panicoController,
                                readOnly: true,
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  labelText: "Estado",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 16),

                        // work
                        viewModel.selectedUnitId == null?
                            const SizedBox()
                            :SizedBox(
                          height: 500,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomGoogleMap(
                              deviceId: viewModel.selectedUnitId,
                              isTicketClose: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  
                  const SizedBox(height: 20),
                  
                  /// EVIDENCE BEFORE SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.blue.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Evidencia Antes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        EvidenceGrid(
                          images: viewModel.evidencePhotos,
                          onImagesChanged: (newImages) {
                            setState(() {
                              viewModel.evidencePhotos = newImages;
                            });
                          },
                          onImageDelete: (deletedItem) {
                            setState(() {
                              if (deletedItem['source'] == 'SCREENSHOT_MAPS') {
                                viewModel.isEvidenceUnitUserStart = false;
                              }
                            });
                          },
                          maxImages: 6,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  /// EVIDENCE AFTER SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.photo_camera_rounded,
                                color: Colors.green.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Evidencia Después',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        EvidenceGrid(
                          images: viewModel.evidenceClosePhotos,
                          onImagesChanged: (newImages) {
                            setState(() {
                              viewModel.evidenceClosePhotos = newImages;
                            });
                          },
                          onImageDelete: (deletedItem) {
                            setState(() {
                              if (deletedItem['source'] == 'SCREENSHOT_COMPONENTS') {
                                viewModel.urlImgComponent = null;
                                viewModel.isValidateComponent = false;
                              } else if (deletedItem['source'] == 'SCREENSHOT_MAPS') {
                                viewModel.urlImgMaps = null;
                                viewModel.isEvidenceUnitUserClose = false;
                              }
                            });
                          },
                          maxImages: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: viewModel.isLoading ? null : () {
                      viewModel.createTicketCombined(
                        context: context,
                        isUpdate: isUpdate,
                        idTicket: widget.ticket?.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: viewModel.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isUpdate ? 'Guardar' : 'Enviar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //  INPUTS SELECTED

  Widget _branchField(ListTicketViewmodel vm) {
    return SelectorField(
      label: 'Empresa',
      icon: Icons.business,
      value: vm.companyController.text.isEmpty ? null : vm.companyController.text,
      onTap: () => {
        _selectBranch(vm)
      },
    );
  }

  Widget _installerField(ListTicketViewmodel vm) {
    return SelectorField(
      label: 'Instalador',
      icon: Icons.person_search_outlined,
      value: vm.selectedInstaller?.full_name ?? (vm.installerController.text.isEmpty ? null : vm.installerController.text),
      onTap: () => _selectInstaller(vm),
    );
  }

  Widget _unitField(ListTicketViewmodel vm) {
    return SelectorField(
      label: 'Unidad',
      icon: Icons.bus_alert,
      value: vm.selectedUnit ?? (vm.unitController.text.isEmpty ? null : vm.unitController.text),
      onTap: () => _selectUnit(vm),
    );
  }


  Future<void> _selectBranch(ListTicketViewmodel vm) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar Empresa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: const Text('BUSMEN'),
                trailing: vm.companyController.text == 'BUSMEN' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () async {
                  await vm.loadExternalUnits('BUSMEN');
                  setState(() {
                    vm.companyController.text = 'BUSMEN';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectInstaller(ListTicketViewmodel vm) async {
    List<ApiResInstaller> filteredInstallers = List.from(vm.installers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 432
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleccionar Instalador',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar instalador...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredInstallers = vm.installers
                                .where((i) => i.full_name.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: filteredInstallers.isEmpty
                          ? const Center(child: Text('No se encontraron instaladores'))
                          : ListView.builder(
                              itemCount: filteredInstallers.length,
                              itemBuilder: (context, index) {
                                final installer = filteredInstallers[index];
                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(installer.full_name),
                                  subtitle: Text(installer.email),
                                  onTap: () {
                                    vm.setSelectedInstaller(installer);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectUnit(ListTicketViewmodel vm) async {
    List<String> filteredUnits = List.from(vm.units);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleccionar Unidad',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar unidad...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredUnits = vm.units
                                .where((u) => u.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: filteredUnits.isEmpty
                          ? const Center(child: Text('No se encontraron unidades'))
                          : ListView.builder(
                              itemCount: filteredUnits.length,
                              itemBuilder: (context, index) {
                                final unit = filteredUnits[index];
                                return ListTile(
                                  leading: const Icon(Icons.directions_car),
                                  title: Text(unit),
                                  onTap: () {
                                    vm.setSelectedUnit(
                                      unit: unit,
                                      company: vm.companyController.text,
                                      isInit: false,
                                    );
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


}
