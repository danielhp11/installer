import 'package:flutter/material.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/view/login_view.dart';
import 'package:instaladores_new/viewModel/evidence_start_finish_viewmodel.dart';
import 'package:instaladores_new/widget/bottom_sheet_utils.dart';
import 'package:instaladores_new/widget/inbox_item_card.dart';
import 'package:instaladores_new/viewModel/list_ticket_viewmodel.dart';
import 'package:provider/provider.dart';

import '../service/request_service.dart';

class ListTicketView extends StatefulWidget {
  const ListTicketView({super.key});

  @override
  State<ListTicketView> createState() => _ListTicketViewState();
}

class _ListTicketViewState extends State<ListTicketView> {
  final DateTime today = DateTime.now();
  bool _showExtraFilters = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final dateInit = "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";

      final vm = context.read<ListTicketViewmodel>();
      vm.controllerDateStart.text = RequestServ.isDebug? "01/01/2026" : dateInit;
      vm.controllerDateEnd.text = RequestServ.isDebug? "31/01/2026" : dateInit;

      if( RequestServ.isDebug ) {
        print("<=================================================================================================================================>");
        print("DATE INIT => START ${vm.controllerDateStart.text} | END ${vm.controllerDateEnd.text}");
        print("<=================================================================================================================================>");
      }

      _showBranchSelectionDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListTicketViewmodel>();
    String company = UserSession().branchRoot;
    String nameUser = UserSession().nameUser;
    String nameType = UserSession().isMaster ? 'Master' : 'Instalador';

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _showConfirmationDialog(context),
          tooltip: 'Cerrar Sesión',
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tickets - $company',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '[$nameType] $nameUser',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_rounded),
            tooltip: 'Cambiar Empresa',
            onPressed: () => _showBranchSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadTickets(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(viewModel),
          Expanded(child: _buildBody(viewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFuelFormBottomSheet(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Revisión'),
        elevation: 6,
      ),
    );
  }

  void _showBranchSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final currentBranch = UserSession().branchRoot;
        
        return AlertDialog(
          title: const Text('Seleccionar Empresa', textAlign: TextAlign.center),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _branchOption(
                context,
                title: 'BUSMEN',
                icon: Icons.directions_bus,
                isSelected: currentBranch == 'BUSMEN',
                onTap: () => _selectBranch(context, 'BUSMEN'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _branchOption(BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600]),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  void _selectBranch(BuildContext context, String branch) {
    UserSession().branchRoot = branch;
    Navigator.pop(context);

    context.read<ListTicketViewmodel>().loadTickets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Empresa cambiada a $branch'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDate({bool isStartDate = true, required ListTicketViewmodel vm}) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );

    TextEditingController controller = isStartDate? vm.controllerDateStart: vm.controllerDateEnd;

    if (date != null) {
      controller.text = "${date.day}/${date.month}/${date.year}";
      vm.loadTickets();
    }
  }

  Widget _buildFilters(ListTicketViewmodel vm) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador colapsable
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                SearchBar(
                  hintText: 'Buscar por unidad...',
                  leading: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
                  onChanged: (value) => vm.setSearchQuery(value),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.08)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                ),
                const SizedBox(height: 12),
              ],
            ),
            crossFadeState: _showSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: vm.controllerDateStart,
                            readOnly: true,
                            onTap: () => _pickDate(vm: vm),
                            decoration: InputDecoration(
                              labelText: "Fecha inicio",
                              labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
                              isDense: true,
                              suffixIcon: Icon(Icons.calendar_today_rounded, color: Theme.of(context).primaryColor, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: vm.controllerDateEnd,
                            readOnly: true,
                            onTap: () => _pickDate(isStartDate: false, vm: vm),
                            decoration: InputDecoration(
                              labelText: "Fecha final",
                              labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
                              isDense: true,
                              suffixIcon: Icon(Icons.event_rounded, color: Theme.of(context).primaryColor, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Botones apilados en Columna para ahorrar espacio horizontal
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón para expandir buscador
                  Material(
                    color: _showSearch ? Theme.of(context).primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => setState(() => _showSearch = !_showSearch),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                          color: _showSearch ? Colors.white : Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Botón para expandir filtros
                  Material(
                    color: _showExtraFilters ? Theme.of(context).primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => setState(() => _showExtraFilters = !_showExtraFilters),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _showExtraFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                          color: _showExtraFilters ? Colors.white : Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sección colapsable de filtros adicionales
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text(
                  'Estado',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Todos Activos',
                        icon: Icons.check_circle_outline_rounded,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.active),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.active),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Abierto',
                        icon: Icons.lock_open_rounded,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.open),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.open),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Proceso',
                        icon: Icons.pending_actions_rounded,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.process),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.process),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'P. Validación',
                        icon: Icons.rule_rounded,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.pending),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.pending),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Cerrado',
                        icon: Icons.lock_rounded,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.closed),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.closed),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Cancelados',
                        icon: Icons.cancel_outlined,
                        isSelected: vm.selectedFilters.contains(TicketFilterOption.cancelled),
                        onSelected: () => vm.toggleFilterOption(TicketFilterOption.cancelled),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ordenar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SortChip(
                      label: 'Más Recientes',
                      icon: Icons.arrow_downward_rounded,
                      isSelected: vm.sortOption == TicketSortOption.dateDesc,
                      onSelected: () => vm.setSortOption(TicketSortOption.dateDesc),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Más Antiguos',
                      icon: Icons.arrow_upward_rounded,
                      isSelected: vm.sortOption == TicketSortOption.dateAsc,
                      onSelected: () => vm.setSortOption(TicketSortOption.dateAsc),
                    ),
                  ],
                ),
              ],
            ),
            crossFadeState: _showExtraFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ListTicketViewmodel vm) {
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (vm.tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No se encontraron tickets', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: vm.tickets.length,
      itemBuilder: (context, index) {
        return InboxItemCard(item: vm.tickets[index]);
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Salir'),
          content: const Text('¿Deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                UserSession().clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
