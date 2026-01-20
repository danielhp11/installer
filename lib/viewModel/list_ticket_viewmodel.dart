import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../service/request_service.dart';
import '../service/response_service.dart';
import '../service/socket_serv.dart';
import '../service/user_session_service.dart';

enum TicketSortOption { dateDesc, dateAsc, status, unit }
enum TicketFilterOption { active, cancelled, open, process, pending, closed }

class ListTicketViewmodel extends ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;

  final _socket = SocketServ.instance;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // region TICKET VIEW
  List<ApiResTicket> _tickets = [];
  TicketSortOption _sortOption = TicketSortOption.dateDesc;
  Set<TicketFilterOption> _selectedFilters = {TicketFilterOption.active};
  String _searchQuery = '';

  List<ApiResTicket> get tickets {
    // Obtenemos la compañía seleccionada actualmente de la sesión
    final String currentBranch = UserSession().branchRoot.toUpperCase().trim();
    final String currentUserName = UserSession().nameUser;

    List<ApiResTicket> filtered = _tickets.where((ticket) {
      // 1. Filtrar por compañía seleccionada (Solo mostrar tickets de la empresa actual)
      final String ticketCompany = (ticket.company ?? '').toUpperCase().trim();
      if (ticketCompany != currentBranch) {
        return false;
      }

      // 2. Si no es Master, solo mostrar tickets asignados a este técnico
      if (!UserSession().isMaster && ticket.technicianName != currentUserName) {
        return false;
      }

      final query = _searchQuery.toLowerCase();

      // Búsqueda específica por unitId (Nombre de unidad)
      final matchesUnit = ticket.unitId.toLowerCase().contains(query);

      // Búsqueda secundaria opcional por título para flexibilidad
      final matchesTitle = ticket.title.toLowerCase().contains(query);

      final statusUpper = ticket.status.toUpperCase();
      final isCancelled = statusUpper == "CANCELADO";

      // Filtro de estado (Selección múltiple)
      bool stateMatch = false;
      for (var filter in _selectedFilters) {
        bool currentMatch = false;
        switch (filter) {
          case TicketFilterOption.active:
            currentMatch = !isCancelled;
            break;
          case TicketFilterOption.cancelled:
            currentMatch = isCancelled;
            break;
          case TicketFilterOption.open:
            currentMatch = statusUpper == "ABIERTO";
            break;
          case TicketFilterOption.process:
            currentMatch = statusUpper == "PROCESO";
            break;
          case TicketFilterOption.pending:
            currentMatch = statusUpper == "PENDIENTE_VALIDACION";
            break;
          case TicketFilterOption.closed:
            currentMatch = statusUpper == "CERRADO";
            break;
        }
        if (currentMatch) {
          stateMatch = true;
          break;
        }
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
  Set<TicketFilterOption> get selectedFilters => _selectedFilters;
  String get searchQuery => _searchQuery;

  void setSortOption(TicketSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleFilterOption(TicketFilterOption option) {
    if (_selectedFilters.contains(option)) {
      if (_selectedFilters.length > 1) {
        _selectedFilters.remove(option);
      }
    } else {
      // Si seleccionamos 'active', limpiamos los demás estados específicos de activos
      if (option == TicketFilterOption.active) {
        _selectedFilters.clear();
      } else if (option == TicketFilterOption.cancelled) {
        // Si seleccionamos 'cancelled', limpiamos todo lo demás para evitar confusión
        _selectedFilters.clear();
      } else {
        // Si seleccionamos un estado específico, quitamos 'active' y 'cancelled'
        _selectedFilters.remove(TicketFilterOption.active);
        _selectedFilters.remove(TicketFilterOption.cancelled);
      }
      _selectedFilters.add(option);
    }
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
        localUnitBusmen = busmenUnits;
        combinedNames.addAll(localUnitBusmen.map((u) => u.name.toString()));
      }
      if (temsaUnits != null && !isBusmenUnit) {
        temsaUnits.sort((a, b) => a.name.toString().toLowerCase().compareTo(b.name.toString().toLowerCase()));
        localUnitTemsa = temsaUnits;
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
  TextEditingController lectorasController = TextEditingController(text: "Cargando lectoras...");
  TextEditingController panicoController = TextEditingController(text: "Cargando botón...");

  List<Map<String, String>> evidencePhotos = [];

  void resetEvidenceStart() {
    evidencePhotos = [];
    descriptionStartController.clear();
    lectorasController.text = "Cargando lectoras...";
    panicoController.text = "Cargando botón...";
    notifyListeners();
  }
  // endregion BTN SHEET START JOB TICKET VIEW

  // region BTN SHEET CLOSE JOB TICKET VIEW
  final formKeyCloseJob = GlobalKey<FormState>();
  TextEditingController descriptionCloseController = TextEditingController();
  List<Map<String, String>> evidenceClosePhotos = [];

  void resetEvidenceClose() {
    evidenceClosePhotos = [];
    descriptionCloseController.clear();
    notifyListeners();
  }
  // endregion BTN SHEET CLOSE JOB TICKET VIEW

  // region TICKET VIEW
  Future<void> loadTickets()async{
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final serv = RequestServ.instance;

    try{
      List<ApiResTicket>? ticketsRecuperados = await serv.handlingRequestParsed<List<ApiResTicket>>(
        urlParam: RequestServ.urlGetTickets,
        asJson: true,
        fromJson: (json) {
          final list = json as List<dynamic>;
          return list.map((item) => ApiResTicket.fromJson(item)).toList();
        },
      );

      _tickets = ticketsRecuperados ?? [];

      // Actualizar la lista de unidades únicas filtradas por la compañía actual
      final String currentBranch = UserSession().branchRoot.toUpperCase().trim();
      
      // Lista base de unidades filtrada por empresa
      _units = _tickets
          .where((t) => (t.company ?? '').toUpperCase().trim() == currentBranch)
          .map((t) => t.unitId)
          .toSet()
          .toList();
      
      // Si no es Master, filtrar unidades solo de SUS tickets asignados
      if( !UserSession().isMaster ){
        _units = _tickets
            .where((t) => 
                (t.company ?? '').toUpperCase().trim() == currentBranch && 
                t.technicianName == UserSession().nameUser)
            .map((t) => t.unitId)
            .toSet()
            .toList();
      }

      _units.sort();

    }catch(e){
      _errorMessage = e.toString();
      print("[ ERR ] LOAD TICKETS: $e");
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

      if (installerController.text.isEmpty) return;

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
    Future<void> deleteTicket({required BuildContext context, int? idTicket, String? reason}) async{

      _isLoading = true;
      _errorMessage = null;

      Navigator.of(context).pop();


      try{

        bool isSuccessful = await deleteTicketTest(
          ticketId : idTicket!,
          modifierId: UserSession().idUser.toString(),
          updatedByName : UserSession().nameUser,
          reason: reason,
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
      required String modifierId,
      required String updatedByName,
      String? reason,
    }) async {

      String url_new = "${RequestServ.baseUrlNor}${RequestServ.urlGetTickets}/$ticketId";

      final Uri url = Uri.parse(url_new).replace(
        queryParameters: {
          'modifier_id': modifierId.toString(),
          'updatedByName': updatedByName,
          if (reason != null && reason.isNotEmpty) 'cancellation_reason': reason,
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
    Future<void> sendEvidence({required BuildContext context, int? idTicket, ApiResTicket? ticket}) async{

      if (!formKeyStartJob.currentState!.validate()) return;

      if( evidencePhotos.isEmpty ) return;


      try{

        // region CAMBIAR ESTATUS
        print("=====>1. CHANGE STATUS <====");
        await updateStatus(
            idTicket.toString(),
            "PROCESO",
            UserSession().nameUser
        );
        // endregion CAMBIAR ESTATUS

        // region SUBIR FOTO
        print("=====>2. ITERATION TO SAVE PHOTO <====");
        // Usamos un loop for para esperar secuencialmente la subida de cada foto
        for (int i = 0; i < evidencePhotos.length; i++) {
          final photoData = evidencePhotos[i];
          String? path = photoData['path'];
          if (path != null) {
            String? imageUrl = await uploadPhoto(path);
            if (imageUrl != null) {
              print("Uploaded: $imageUrl");
              await registerEvidence(idTicket.toString(), imageUrl, "PROCESO", i + 1);
            }
          }
        }
        // endregion SUBIR FOTO

        // region ENVIAR FORMULARIO
        print("=====>4. SEND FORM  <====");
        Map<String, dynamic> data = {
          "technician": ticket?.technicianName,
          "unit": ticket?.unitId,
          "observations": descriptionStartController.text,
          "timestamp": DateTime.now().toIso8601String()
        };
        await sendFormData(idTicket.toString(), "PROCESO", data);
        // endregion ENVIAR FORMULARIO

        loadTickets();
        _isLoading = false;
        Navigator.pop(context); // Cerramos el panel al terminar
        notifyListeners();
      }catch(e){
        print("[ ERROR ] STAT JOB ACTIVITY ${e.toString()}");
      }
    }
  // endregion BTN SHEET START JOB TICKET VIEW

  // region BTN SHEET CLOSE JOB TICKET VIEW
  Future<void> sendEvidenceClose({required BuildContext context, int? idTicket, ApiResTicket? ticket}) async{

    if (!formKeyCloseJob.currentState!.validate()) return;

    if( evidenceClosePhotos.isEmpty ) return;


    try{

      // region CAMBIAR ESTATUS
      print("=====>1. CHANGE STATUS <====");
      await updateStatus(
          idTicket.toString(),
          "PENDIENTE_VALIDACION",
          UserSession().nameUser
      );
      // endregion CAMBIAR ESTATUS

      // region SUBIR FOTO
      print("=====>2. ITERATION TO SAVE PHOTO <====");
      // Usamos un loop for para esperar secuencialmente la subida de cada foto
      for (int i = 0; i < evidenceClosePhotos.length; i++) {
        final photoData = evidenceClosePhotos[i];
        String? path = photoData['path'];
        if (path != null) {
          String? imageUrl = await uploadPhoto(path);
          if (imageUrl != null) {
            print("Uploaded: $imageUrl");
            await registerEvidence(idTicket.toString(), imageUrl, "PENDIENTE_VALIDACION", i + 1);
          }
        }
      }
      // endregion SUBIR FOTO

      // region ENVIAR FORMULARIO
      print("=====>4. SEND FORM  <====");
      Map<String, dynamic> data = {
        "technician": ticket?.technicianName,
        "unit": ticket?.unitId,
        "observations": descriptionStartController.text,
        "timestamp": DateTime.now().toIso8601String()
      };
      await sendFormData(idTicket.toString(), "PENDIENTE_VALIDACION", data);
      // endregion ENVIAR FORMULARIO

      loadTickets();
      _isLoading = false;
      Navigator.pop(context); // Cerramos el panel al terminar
      notifyListeners();
    }catch(e){
      print("[ ERROR ] STAT JOB ACTIVITY ${e.toString()}");
    }
  }
  // endregion BTN SHEET CLOSE JOB TICKET VIEW

  // region SOCKET
  void initSocket() {
    lectorasController.text = "Buscando unidad...";
    panicoController.text = "Buscando unidad...";
    _socket.onUnitUpdate = (data) {
      _updateUnitPosition(data);
    };

    _socket.connect();
  }

  Future<void> _updateUnitPosition(Map<String, dynamic> data) async {

    if (!data.containsKey('positions')) return;

    final positions = data['positions'];
    if (positions is! List || positions.isEmpty) return;

    final pos = positions.first;
    final deviceId = pos['deviceId'] as int;
    print("device id socket => $deviceId");
  }

  void disconnectSocket() {
    _socket.disconnect();
    notifyListeners();
  }
  // endregion SOCKET

  // region UTILITIES
  // 1.
  Future<void> updateStatus(String ticketId, String status, String changedBy) async {
    // print("url => ${RequestServ.baseUrlNor}tickets/$ticketId/status");
    final response = await http.put(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'status': status,
        'changedBy': changedBy,
      }),
    );
    // print("=> param ${
    //     {
    //       'status': status,
    //       'changedBy': changedBy,
    //     }
    // }");
    print(response.headers);
  }

  // 2.
  Future<String?> uploadPhoto(String filePath) async {
    // print("url => ${RequestServ.baseUrlNor}tickets/upload");
    // print("file => ${filePath}");
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${RequestServ.baseUrlNor}tickets/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['imageUrl']?.toString();
      } else {
        // print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // print("Error uploading: $e");
      return null;
    }
  }

  // 3.
  Future<void> registerEvidence(String ticketId, String imageUrl, String phase, int sequence) async {
    // print("url => ${RequestServ.baseUrlNor}tickets/$ticketId/evidence");
    // print("${
    //     {
    //       'imageUrl': imageUrl,
    //       'phase': phase,
    //       'sequence': sequence,
    //     }
    // }");
    final response = await http.post(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/evidence'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'imageUrl': imageUrl,
        'phase': phase,
        'sequence': sequence,
      }),
    );
    // print(response);
  }

  // 4.
  Future<void> sendFormData(String ticketId, String formType, Map<String, dynamic> data) async {
    // print("url => ${RequestServ.baseUrlNor}tickets/$ticketId/form-data");
    // print("${
    //     {
    //       'formType': formType,
    //       'data': data,
    //     }
    // }");
    final response = await http.post(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/form-data'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'formType': formType,
        'data': data,
      }),
    );
    // print(response);
  }
  // endregion UTILITIES

}
