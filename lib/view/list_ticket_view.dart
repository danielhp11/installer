import 'package:flutter/material.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/view/login_view.dart';
import 'package:instaladores_new/view/widget/bottom_sheet_utils.dart';
import 'package:instaladores_new/view/widget/inbox_item_card.dart';
import 'package:instaladores_new/viewModel/list_ticket_viewmodel.dart';
import 'package:provider/provider.dart';

class ListTicketView extends StatefulWidget {
  const ListTicketView({super.key});

  @override
  State<ListTicketView> createState() => _ListTicketViewState();
}

class _ListTicketViewState extends State<ListTicketView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Cargamos los tickets iniciales
      context.read<ListTicketViewmodel>().loadTickets();
      
      // Abrimos el diálogo de selección de empresa siempre al iniciar
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
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () => _showConfirmationDialog(context),
        ),
        title: Column(
          children: [

            Text('Tickets - $company'),
            Text('[ $nameType ] - $nameUser',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Raleway',
                )
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_center_outlined),
            tooltip: 'Cambiar Empresa',
            onPressed: () => _showBranchSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadTickets(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(viewModel),
          Expanded(child: _buildBody(viewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFuelFormBottomSheet(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showBranchSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Forzamos a que seleccione una opción si es la primera vez
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
              const SizedBox(height: 12),
              _branchOption(
                context,
                title: 'TEMSA',
                icon: Icons.local_shipping,
                isSelected: currentBranch == 'TEMSA',
                onTap: () => _selectBranch(context, 'TEMSA'),
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
    // Recargar tickets para la nueva rama seleccionada
    context.read<ListTicketViewmodel>().loadTickets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Empresa cambiada a $branch'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFilters(ListTicketViewmodel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            hintText: 'Buscar por título, unidad o estatus...',
            leading: const Icon(Icons.search),
            onChanged: (value) => vm.setSearchQuery(value),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.1)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TicketFilterOption>(
              segments: const [
                ButtonSegment(
                  value: TicketFilterOption.active,
                  label: Text('Activos'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: TicketFilterOption.cancelled,
                  label: Text('Cancelados'),
                  icon: Icon(Icons.cancel_outlined),
                ),
              ],
              selected: {vm.filterOption},
              onSelectionChanged: (Set<TicketFilterOption> newSelection) {
                vm.setFilterOption(newSelection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Ordenar: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Recientes',
                  icon: Icons.arrow_downward,
                  isSelected: vm.sortOption == TicketSortOption.dateDesc,
                  onSelected: () => vm.setSortOption(TicketSortOption.dateDesc),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Antiguos',
                  icon: Icons.arrow_upward,
                  isSelected: vm.sortOption == TicketSortOption.dateAsc,
                  onSelected: () => vm.setSortOption(TicketSortOption.dateAsc),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Estatus',
                  icon: Icons.info_outline,
                  isSelected: vm.sortOption == TicketSortOption.status,
                  onSelected: () => vm.setSortOption(TicketSortOption.status),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Unidad',
                  icon: Icons.directions_car,
                  isSelected: vm.sortOption == TicketSortOption.unit,
                  onSelected: () => vm.setSortOption(TicketSortOption.unit),
                ),
              ],
            ),
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
