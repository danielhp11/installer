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

class _ListTicketViewState extends State<ListTicketView>{

  @override
  void initState(){
    super.initState();
    Future.microtask((){
      context.read<ListTicketViewmodel>().loadTickets();
    });
  }



  @override
  Widget build(BuildContext context){

    final viewModel = context.watch<ListTicketViewmodel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () {
            // print("Exit to session");
            _showConfirmationDialog(context);
          },
        ),
        title: const Text('Tickets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () {
              // print("update list ticket");
              viewModel.loadTickets();
            },
          ),
        ],
      ),

      body: _buildBody(viewModel),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // viewModel.openAddCard(context, null);
          showFuelFormBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),

    );
  }

  Widget _buildBody(ListTicketViewmodel vm){

    if(vm.isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vm.tickets.length,
      itemBuilder: (context, index) {
        final ticket = vm.tickets[index];
        return InboxItemCard( item:ticket, onTap: () => print("open btn sheet to new ticket ${ticket.status}"), );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // evita cerrar tocando fuera del diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Salir'),
          content: const Text('¿Deseas confirmar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // solo cierra el diálogo
              },
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