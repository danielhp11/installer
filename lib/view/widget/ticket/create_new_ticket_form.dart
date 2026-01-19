import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/request_service.dart';
import '../../../service/response_service.dart';
import '../../../service/user_session_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';
import '../selector_field.dart';
import '../text_field_widget.dart';

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
    
    // Cargamos instaladores
    vm.getInstaller();
    
    // Cargamos y combinamos unidades de Busmen y Temsa
    await vm.loadExternalUnits(UserSession().branchRoot);

    if (widget.ticket != null) {
      // Editar: llenar con datos
      if (mounted) {
        vm.companyController.text = widget.ticket!.company ?? '';
        vm.installerController.text = widget.ticket!.technicianName;
        vm.unitController.text = widget.ticket!.unitId;
        vm.descriptionController.text = widget.ticket!.description;
        vm.selectedUnitId = widget.ticket!.unitId.toString() != "null"?  int.parse(widget.ticket!.unitId):0;
        // Intentar auto-seleccionar la unidad si ya existe en la lista
        if (vm.units.contains(widget.ticket!.unitId)) {
          vm.setSelectedUnit(unit : widget.ticket!.unitId);
        }
        setState(() {
          isUpdate = true;
        });
        // print("Update ticket # ${widget.ticket?.id} => ${isUpdate}");
      }
    } else {
      // Nuevo: Limpiar campos anteriores
      if (mounted) {
        vm.resetForm();
        // Valor por defecto basado en la rama seleccionada
        vm.companyController.text = UserSession().branchRoot;
        setState(() {
          isUpdate = false;
        });
      }
    }

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
          key: viewModel.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  children: [
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
                    textField(viewModel.descriptionController, 'Descripcion', Icons.text_snippet_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (isUpdate) {
                    viewModel.createTicket(
                      context: context,
                      isUpdate: true,
                      idTicket: widget.ticket!.id,
                    );
                  } else {
                    viewModel.createTicket(context: context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isUpdate ? 'Guardar' : 'Crear',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(
           isUpdate ? 'Actualizar ticket' : 'Crear ticket',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

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


  // ================= LOGIC =================

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
              ListTile(
                leading: const Icon(Icons.local_shipping),
                title: const Text('TEMSA'),
                trailing: vm.companyController.text == 'TEMSA' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () async {
                  await vm.loadExternalUnits('TEMSA');
                  setState(() {
                    vm.companyController.text = 'TEMSA';
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
                'Seleccionar Instalador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.installers.length,
                  itemBuilder: (context, index) {
                    final installer = vm.installers[index];
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
        );
      },
    );
  }

  Future<void> _selectUnit(ListTicketViewmodel vm) async {
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
                'Seleccionar Unidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.units.length,
                  itemBuilder: (context, index) {
                    final unit = vm.units[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(unit),
                      onTap: () {
                        // print(unit);
                        vm.setSelectedUnit(unit: unit, index: index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


}
