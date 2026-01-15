import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../service/request_service.dart';
import '../service/response_service.dart';

enum TicketSortOption { dateDesc, dateAsc, status, unit }
enum TicketFilterOption { active, cancelled }

class ListTicketViewmodel extends ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;
  
  // region TICKET VIEW
  List<ApiResTicket> _tickets = [];
  TicketSortOption _sortOption = TicketSortOption.dateDesc;
  TicketFilterOption _filterOption = TicketFilterOption.active;
  String _searchQuery = '';

  List<ApiResTicket> get tickets {
    List<ApiResTicket> filtered = _tickets.where((ticket) {
      final query = _searchQuery.toLowerCase();
      
      // Búsqueda específica por unitId (Nombre de unidad)
      final matchesUnit = ticket.unitId.toLowerCase().contains(query);
      
      // Búsqueda secundaria opcional por título para flexibilidad
      final matchesTitle = ticket.title.toLowerCase().contains(query);

      final isCancelled = ticket.status.toUpperCase() == "CANCELADO";
      
      // Primero evaluamos el filtro de estado
      bool stateMatch = false;
      if (_filterOption == TicketFilterOption.active) {
        stateMatch = !isCancelled;
      } else {
        stateMatch = isCancelled;
      }

      // Si hay búsqueda, debe coincidir con la unidad (o título) Y con el estado
      if (query.isNotEmpty) {
        return (matchesUnit || matchesTitle) && stateMatch;
      }
      
      return stateMatch;
    }).toList();

    // Lógica de ordenamiento corregida
    switch (_sortOption) {
      case TicketSortOption.dateDesc:
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a.create_at ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b.create_at ?? '') ?? DateTime(0);
          return dateB.compareTo(dateA); // Mayor a menor
        });
        break;
      case TicketSortOption.dateAsc:
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a.create_at ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b.create_at ?? '') ?? DateTime(0);
          return dateA.compareTo(dateB); // Menor a mayor
        });
        break;
      case TicketSortOption.status:
        filtered.sort((a, b) => a.status.toLowerCase().compareTo(b.status.toLowerCase()));
        break;
      case TicketSortOption.unit:
        filtered.sort((a, b) => a.unitId.toLowerCase().compareTo(b.unitId.toLowerCase()));
        break;
    }
    return filtered;
  }

  TicketSortOption get sortOption => _sortOption;
  TicketFilterOption get filterOption => _filterOption;
  String get searchQuery => _searchQuery;

  void setSortOption(TicketSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterOption(TicketFilterOption option) {
    _filterOption = option;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  // endregion TICKET VIEW

  // region BTN SHEET NEW TICKET VIEW
  final formKey = GlobalKey<FormState>();
  TextEditingController companyController = TextEditingController();
  TextEditingController installerController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  // endregion BTN SHEET NEW TICKET VIEW

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;


  // region TICKET VIEW
  Future<void> loadTickets()async{
    _isLoading = true;
    _errorMessage = null;

    final serv = RequestServ.instance;

    try{
      _tickets.clear();
      List<ApiResTicket>? ticketsRecuperados = await serv.handlingRequestParsed<List<ApiResTicket>>(
        urlParam: RequestServ.urlGetTickets,
        asJson: true,
        fromJson: (json) {
          final list = json as List<dynamic>;
          return list.map((item) => ApiResTicket.fromJson(item)).toList();
        },
      );

      _tickets = ticketsRecuperados ?? [];
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }

  }

  void resetForm() {
    companyController.clear();
    installerController.clear();
    unitController.clear();
    descriptionController.clear();
  }
// endregion TICKET VIEW

// region BTN SHEET NEW TICKET VIEW
  Future<void> createTicket({required BuildContext context, bool isUpdate = false, String? idTicket}) async{

    if (!formKey.currentState!.validate()) return;

    _isLoading = true;
    _errorMessage = null;

    final serv = RequestServ.instance;

    try{
      String url = isUpdate? "${RequestServ.urlGetTickets}/${idTicket}/status":"${RequestServ.urlGetTickets}/";
      String method = isUpdate? "PUT":"POST";

      Map<String, dynamic> param = isUpdate?
        {
          "title": "",
          "description": descriptionController.text,
          "priority": "",
          "category": "",
          "status": "ABIERTO",
          "technicianName": installerController.text,
          "unitId": unitController.text,
          "company": companyController.text.toUpperCase(),
          "id": idTicket,
          "createdAt": "2026-01-15T15:01:18.543Z",
          "evidences": [],
          "formsData": [],
          "history": []
        }:{
        "title": "",
        "description": descriptionController.text,
        "priority": "",
        "category": "",
        "status": "ABIERTO",
        "technicianName": installerController.text,
        "unitId": unitController.text,
        "company": companyController.text.toUpperCase(),
      };


      ApiResTicket? ticket = await serv.handlingRequestParsed<ApiResTicket>(
        urlParam: url,
        params: param,
        method: method,
        asJson: true,
        fromJson: (json) => ApiResTicket.fromJson(json),
      );

      if(ticket == null) return;

      loadTickets();

      Navigator.pop(context);
      _isLoading = false;
      notifyListeners();

    }catch(e){
      print("[ ERROR ] CREATE TICKET => ${e.toString()}");
    }
  }
// endregion BTN SHEET NEW TICKET VIEW

// region GET INSTALLER
  Future<void> getInstaller() async {
    final serv = RequestServ.instance;
    try{
      final installer = await serv.handlingRequest(
        urlParam: RequestServ.urlInstaller,
        method: "GET",
        asJson: false,
      );
      print("installer => ${installer}");

    }catch(e){
      print("[ ERR ] GET INSTALLER: ${e.toString()}");
    }
  }
// endregion GET INSTALLER

// region BTN DELETE TICKET VIEW
  Future<void> deleteTicket({required BuildContext context, String? idTicket}) async{

    _isLoading = true;
    _errorMessage = null;

    Navigator.of(context).pop();

    final serv = RequestServ.instance;

    try{
      String url = "${RequestServ.urlGetTickets}/$idTicket";

      await serv.handlingRequest(
        urlParam: url,
        method: "DELETE",
        asJson: true,
      );

      loadTickets();
      _isLoading = false;
      notifyListeners();
    }catch(e){
      print("[ ERROR ] DELETE TICKET ${e.toString()}");
    }
  }
// endregion BTN DELETE TICKET VIEW

}
