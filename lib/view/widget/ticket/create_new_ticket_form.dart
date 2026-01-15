import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/response_service.dart';
import '../../../viewModel/list_ticket_viewmodel.dart';

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
    final vm = context.read<ListTicketViewmodel>();
    vm.getInstaller();
    if (widget.ticket != null) {
      // Editar: llenar con datos
      Future.microtask(() {
        vm.companyController.text = widget.ticket!.company!;
        vm.installerController.text = widget.ticket!.technicianName;
        vm.unitController.text = widget.ticket!.unitId;
        vm.descriptionController.text = widget.ticket!.description;
      });
      isUpdate = true;
    } else {
      // Nuevo: Limpiar campos anteriores
      Future.microtask(() => vm.resetForm());
      isUpdate = false;
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
              // _card(
              //   child: Column(
              //     children: [
              //       // _vehicleField(),
              //       const SizedBox(height: 16),
              //       // _cardField(),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  children: [
                    _textField(viewModel.companyController, 'Empresa', Icons.business),
                    const SizedBox(height: 16),
                    _textField(viewModel.installerController, 'Instalador', Icons.pan_tool),
                    const SizedBox(height: 16),
                    _textField(viewModel.unitController, 'Unidad', Icons.bus_alert),
                    const SizedBox(height: 16),
                    _textField(viewModel.descriptionController, 'Descripcion', Icons.text_snippet_outlined),
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
                child: isUpdate? const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ):Text(
                  'Crear',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        const Text(
          'Crear ticket',
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

  // Widget _vehicleField() {
  //   return SelectorField(
  //     label: 'Vehículo',
  //     icon: Icons.directions_car,
  //     value: _selectedVehicle == null
  //         ? null
  //         : '${_selectedVehicle!.brand} ${_selectedVehicle!.model}',
  //     onTap: _selectVehicle, // Disable tap if vehicle is pre-selected
  //   );
  // }

  // Widget _cardField() {
  //   return SelectorField(
  //     label: 'Tarjeta',
  //     icon: Icons.credit_card,
  //     value: _selectedCard == null
  //         ? null
  //         : '${_selectedCard!.name} • ****${_selectedCard!.number.substring(_selectedCard!.number.length - 4)}',
  //     onTap: _selectCard, // Disable tap if card is pre-selected
  //   );
  // }

  Widget _numberField(
      TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        if (double.tryParse(v) == null) return 'Número inválido';
        return null;
      },
    );
  }

  Widget _textField(
      TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        return null;
      },
    );
  }


// Widget _datePicker() {
  //   return TextFormField(
  //     controller: _dateController,
  //     readOnly: true,
  //     decoration: const InputDecoration(
  //       labelText: 'Fecha',
  //       prefixIcon: Icon(Icons.calendar_today),
  //       border: OutlineInputBorder(),
  //     ),
  //     onTap: () async {
  //       final date = await showDatePicker(
  //         context: context,
  //         initialDate: _selectedDate ?? DateTime.now(),
  //         firstDate: DateTime(2000),
  //         lastDate: DateTime.now(),
  //       );
  //
  //       if (date != null) {
  //         setState(() {
  //           _selectedDate = date;
  //           _dateController.text =
  //               date.toIso8601String().split('T').first;
  //         });
  //       }
  //     },
  //   );
  // }

  // ================= LOGIC =================

  // Future<void> _selectVehicle() async {
  //   final vehicles = context.read<VehicleViewModel>().vehicle;
  //
  //   final selected = await showModalBottomSheet<VehicleModel>(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (_) => SelectionBottomSheet<VehicleModel>(
  //       title: 'Seleccionar vehículo',
  //       items: vehicles,
  //       labelBuilder: (v) => '${v.brand} ${v.model}',
  //       subtitleBuilder: (v) => Text('Placas: ${v.plate}'),
  //     ),
  //   );
  //
  //   if (selected != null) {
  //     setState(() => _selectedVehicle = selected);
  //   }
  // }

  // Future<void> _selectCard() async {
  //   final cards = context.read<CardViewModel>().cards;
  //
  //   final selected = await showModalBottomSheet<CardModel>(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (_) => SelectionBottomSheet<CardModel>(
  //       title: 'Seleccionar tarjeta',
  //       items: cards,
  //       labelBuilder: (c) => c.name,
  //       subtitleBuilder: (c) =>
  //           Text('**** ${c.number.substring(c.number.length - 4)}'),
  //     ),
  //   );
  //
  //   if (selected != null) {
  //     setState(() => _selectedCard = selected);
  //   }
  // }


}