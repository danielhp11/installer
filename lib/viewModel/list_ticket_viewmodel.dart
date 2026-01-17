import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../service/request_service.dart';
import '../service/response_service.dart';
import '../service/user_session_service.dart';

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

  // Cambiado a dynamic para guardar objetos completos y evitar error de subtipo
  List<dynamic> localUnitBusmen = [];
  List<dynamic> localUnitTemsa = [];

  int installerId = 0;
  List<ApiResInstaller> _installers = [];
  List<ApiResInstaller> get installers => _installers;

  ApiResInstaller? _selectedInstaller;
  ApiResInstaller? get selectedInstaller => _selectedInstaller;

  void setSelectedInstaller(ApiResInstaller? installer) {
    _selectedInstaller = installer;
    if (installer != null) {
      installerController.text = installer.full_name;
      installerId = installer.id;
    } else {
      installerController.clear();
      installerId = 0;
    }
    notifyListeners();
  }

  List<String> _units = [];
  List<String> get units => _units;

  String? _selectedUnit;
  String? get selectedUnit => _selectedUnit;
  int? selectedUnitId; // ID de la unidad seleccionada

  void setSelectedUnit({String? unit, int? index}) {
    _selectedUnit = unit;

    // Solo buscamos el ID si el índice es válido
    if (unit != null && index != null && index >= 0) {
      List<dynamic> currentList = UserSession().branchRoot == "BUSMEN" ? localUnitBusmen : localUnitTemsa;
      if (index < currentList.length) {
        selectedUnitId = currentList[index].id;
        print("Unidad seleccionada ID: $selectedUnitId");
      }
    }

    if (unit != null) {
      unitController.text = unit;
    } else {
      unitController.clear();
      selectedUnitId = null;
    }
    notifyListeners();
  }

  Future<void> loadExternalUnits(String nameCompany) async {
    final serv = RequestServ.instance;
    try {
      final busmenUnits =  await serv.fetchStatusDevice(isTemsa: false);
      final temsaUnits = await serv.fetchStatusDevice(isTemsa: true);

      List<String> combinedNames = [];
      bool isBusmenUnit = nameCompany == 'BUSMEN';

      if (busmenUnits != null && isBusmenUnit ) {
        // Ordenamos objetos para que coincidan con la lista de nombres
        busmenUnits.sort((a, b) => a.name.toString().toLowerCase().compareTo(b.name.toString().toLowerCase()));
        localUnitBusmen = busmenUnits as List<dynamic>;
        combinedNames.addAll(localUnitBusmen.map((u) => u.name.toString()));
      }
      if (temsaUnits != null && !isBusmenUnit) {
        temsaUnits.sort((a, b) => a.name.toString().toLowerCase().compareTo(b.name.toString().toLowerCase()));
        localUnitTemsa = temsaUnits as List<dynamic>;
        combinedNames.addAll(localUnitTemsa.map((u) => u.name.toString()));
      }

      _units = combinedNames.toSet().toList(); // Unique
      _units.sort();
      notifyListeners();
    } catch (e) {
      print("[ ERR ] LOAD EXTERNAL UNITS: ${e.toString()}");
    }
  }
  // endregion BTN SHEET NEW TICKET VIEW

  // region BTN SHEET START JOB TICKET VIEW
  final formKeyStartJob = GlobalKey<FormState>();
  TextEditingController descriptionStartController = TextEditingController();
  List<String> evidencePhotos = [];

  void resetEvidence() {
    evidencePhotos = [];
    notifyListeners();
  }
  // endregion BTN SHEET START JOB TICKET VIEW

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
      
      // Extraer unidades únicas de los tickets existentes inicialmente
      if (_units.isEmpty) {
        _units = _tickets.map((t) => t.unitId).toSet().toList();
        _units.sort();
      }
      
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
    _selectedInstaller = null;
    _selectedUnit = null;
    selectedUnitId = null;
    installerId = 0;
  }
// endregion TICKET VIEW

// region BTN SHEET NEW TICKET VIEW
  Future<void> createTicket({required BuildContext context, bool isUpdate = false, int? idTicket}) async{

    if (!formKey.currentState!.validate()) return;

    print("installer => ${installerController.text.toUpperCase()}");
    if (installerController.text.isEmpty) return;

    print("unit => ${unitController.text.toUpperCase()}");
    if (unitController.text.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;

    final serv = RequestServ.instance;

    try{
      String url = isUpdate? "${RequestServ.urlGetTickets}/${idTicket}":"${RequestServ.urlGetTickets}/";
      String method = isUpdate? "PUT":"POST";

      Map<String, dynamic> param = isUpdate?
        {
          "title": "",
          "description": descriptionController.text,
          "priority": "",
          "category": "",
          "status": "ABIERTO",
          "technicianName": installerController.text,
          "unitId": selectedUnitId.toString(),
          "company": companyController.text.toUpperCase(),
          "id": idTicket,
          "createdAt": DateTime.now().toIso8601String(),
          "technicianId": installerId,
          "modifierId": UserSession().idUser,
          "updatedByName": UserSession().nameUser,
          "evidences": [],
          "formsData": [],
          "history": []
        }:{
        "title": "",
        "description": descriptionController.text,
        "priority": "",
        "category": "",
        "status": "ABIERTO",
        "technicianId": installerId,
        "technicianName": installerController.text,
        "unitId": selectedUnitId.toString(),
        "company": companyController.text.toUpperCase(),
      };

      print("param => $param");
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
      resetForm();
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
      List<ApiResInstaller>? installers = await serv.handlingRequestParsed<List<ApiResInstaller>>(
        urlParam: RequestServ.urlInstaller,
        method: "GET",
        asJson: true,
        fromJson: (json) {
          final list = json as List<dynamic>;
          return list.map((item) => ApiResInstaller.fromJson(item)).toList();
        },
      );

      _installers = installers ?? [];
      
      // Auto-seleccionar si el nombre en el controller ya existe en la lista
      if (installerController.text.isNotEmpty && _installers.isNotEmpty) {
        try {
          _selectedInstaller = _installers.firstWhere(
            (element) => element.full_name.toLowerCase() == installerController.text.toLowerCase()
          );
        } catch (_) {
          // No se encontró coincidencia exacta
        }
      }

      notifyListeners();

    }catch(e){
      print("[ ERR ] GET INSTALLER: ${e.toString()}");
    }
  }
// endregion GET INSTALLER

// region BTN DELETE TICKET VIEW
  Future<void> deleteTicket({required BuildContext context, int? idTicket}) async{

    _isLoading = true;
    _errorMessage = null;

    Navigator.of(context).pop();


    try{

      bool isSuccessful = await deleteTicketTest(
        ticketId : idTicket!,
        modifierId: UserSession().idUser,
        updatedByName : UserSession().nameUser,
      );

      if(isSuccessful){
        loadTickets();
        _isLoading = false;
        notifyListeners();
      }


    }catch(e){
      print("[ ERROR ] DELETE TICKET ${e.toString()}");
    }
  }

  Future<bool> deleteTicketTest({
    required int ticketId,
    required int modifierId,
    required String updatedByName,
  }) async {

    String url_new = "${RequestServ.baseUrlNor}${RequestServ.urlGetTickets}/$ticketId";

    final Uri url = Uri.parse(url_new).replace(
      queryParameters: {
        'modifier_id': modifierId.toString(),
        'updatedByName': updatedByName,
      },
    );

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminado correctamente
        return true;
      } else {
        print('Error al eliminar ticket');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception deleteTicket: $e');
      return false;
    }
  }
// endregion BTN DELETE TICKET VIEW

// region BTN SHEET START JOB TICKET VIEW
  Future<void> sendEvidence({required BuildContext context, int? idTicket}) async{

    if (!formKeyStartJob.currentState!.validate()) return;

    if( evidencePhotos.isEmpty ) return;

    final serv = RequestServ.instance;

    try{

      // region CAMBIAR ESTATUS
      String url = "${RequestServ.urlGetTickets}/$idTicket/status";

      await serv.handlingRequest(
        urlParam: url,
        params: {
          "status": "PROCESO",
          "changedBy": UserSession().idUser
        },
        method: "PUT",
        asJson: true,
      );

      // endregion CAMBIAR ESTATUS

      // region SUBIR FOTO

      evidencePhotos.asMap().forEach((index, photo){
        print("ticket id: $idTicket | phase: PROCESO | sequence: ${index+1} | photo: $photo");
        uploadPhoto(photo);
      });
      // endregion SUBIR FOTO

      // region LIGAR FOTO
      evidencePhotos.asMap().forEach((index, photo){
        registerEvidence( idTicket.toString(), photo, "PROCESO", index+1 );
      });
      // endregion LIGAR FOTO

      // region ENVIAR FORMULARIO
      // endregion ENVIAR FORMULARIO

      loadTickets();
      _isLoading = false;
      notifyListeners();
    }catch(e){
      print("[ ERROR ] DELETE TICKET ${e.toString()}");
    }
  }

  Future<String> uploadPhoto(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('${RequestServ.baseUrlNor}/tickets/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['imageUrl']; // Assuming API returns {"imageUrl": "/uploads/..."}
    } else {
      throw Exception('Failed to upload photo: ${response.body}');
    }
  }

  Future<void> registerEvidence(String ticketId, String imageUrl, String phase, int sequence) async {
    final serv = RequestServ.instance;
    try {
      await serv.handlingRequest(
        urlParam: 'evidences',
        method: 'POST',
        asJson: true,
        params: {
          'ticketId': int.parse(ticketId),
          'imageUrl': imageUrl,
          'phase': phase,
          'sequence': sequence,
        },
      );
    } catch (e) {
      print("[ ERR ] REGISTER EVIDENCE: ${e.toString()}");
    }
  }
// endregion BTN SHEET START JOB TICKET VIEW

}
