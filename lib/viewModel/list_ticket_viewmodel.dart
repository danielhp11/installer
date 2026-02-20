import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instaladores_new/widget/alert_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:instaladores_new/service/offline_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../service/request_service.dart';
import '../service/response_service.dart';
import '../service/socket_serv.dart';
import '../service/user_session_service.dart';

enum TicketSortOption { dateDesc, dateAsc, status, unit }
enum TicketFilterOption { active, cancelled, open, process, pending, closed }
enum ComponentStatus { idle, selected, uploading, pending, approved, rejected }

class ListTicketViewmodel extends ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _connectivitySubscription;

  final _socket = SocketServ.instance;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  ListTicketViewmodel() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    // Manejo robusto para diferentes versiones de connectivity_plus
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((dynamic result) {
      bool hasConnection = false;
      if (result is List<ConnectivityResult>) {
        hasConnection = result.isNotEmpty && result.first != ConnectivityResult.none;
      } else if (result is ConnectivityResult) {
        hasConnection = result != ConnectivityResult.none;
      }

      if (hasConnection) {
        debugPrint("--- RED DETECTADA: DISPARANDO SINCRONIZACIÓN ---");
        _triggerSync();
      }
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // region TICKET VIEW
  List<ApiResTicket> _tickets = [];
  TicketSortOption _sortOption = TicketSortOption.dateDesc;
  Set<TicketFilterOption> _selectedFilters = {TicketFilterOption.active};
  String _searchQuery = '';
  TextEditingController controllerDateStart = TextEditingController();
  TextEditingController controllerDateEnd = TextEditingController();

  List<ApiResTicket> get tickets {

    final String currentBranch = UserSession().branchRoot.toUpperCase().trim();
    final String currentUserName = UserSession().nameUser;

    List<ApiResTicket> filtered = _tickets.where((ticket) {

      final String ticketCompany = (ticket.company ?? '').toUpperCase().trim();
      if (ticketCompany != currentBranch) {
        return false;
      }


      if (!UserSession().isMaster && ticket.technicianName != currentUserName) {
        return false;
      }

      final query = _searchQuery.toLowerCase();


      final matchesUnit = ticket.unitId.toLowerCase().contains(query);


      final matchesTitle = ticket.title.toLowerCase().contains(query);

      final statusUpper = ticket.status.toUpperCase();
      final isCancelled = statusUpper == "CANCELADO";

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

      if (query.isNotEmpty) {
        return (matchesUnit || matchesTitle) && stateMatch;
      }

      return stateMatch;
    }).toList();

    // FILTER ORDER ASIC OR DESC
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

      if (option == TicketFilterOption.active) {
        _selectedFilters.clear();
      } else if (option == TicketFilterOption.cancelled) {

        _selectedFilters.clear();
      } else {

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

  bool isLoadNewUpdate = false;

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
  int? selectedUnitId;

  void setSelectedUnit({String? unit, required String company, bool isInit = false }) {
    _selectedUnit = unit;
    // String textText = isInit? "Init load":"Change";

    List<dynamic> currentList = company == "BUSMEN" ? localUnitBusmen : localUnitTemsa;
    currentList.forEach((things){
      bool validate = isInit? things.id == unit : things.name == unit;

      if(validate){

        selectedUnitId = things.id;
      }
    });

    if (unit != null) {
      unitController.text = unit;
      // Iniciar socket al seleccionar unidad
      if (selectedUnitId != null) {
        initSocket(selectedUnitId.toString(), company);
      }
    } else {
      unitController.clear();
      selectedUnitId = null;
      disconnectSocket();
    }
    notifyListeners();
  }

  Future<void> loadExternalUnits(String nameCompany, {bool forceRefresh = false}) async {
    final serv = RequestServ.instance;
    try {
      List<String> combinedNames = [];
      bool isBusmenUnit = nameCompany == 'BUSMEN';

      if (isBusmenUnit) {
        if (localUnitBusmen.isEmpty || forceRefresh) {
          final busmenUnits = await serv.fetchStatusDevice(isTemsa: false);
          if (busmenUnits != null) {
            busmenUnits.sort((a, b) => a.name.toString().toLowerCase().compareTo(b.name.toString().toLowerCase()));
            localUnitBusmen = busmenUnits;
          }
        }
        combinedNames.addAll(localUnitBusmen.map((u) => u.name.toString()));
      } else {
        if (localUnitTemsa.isEmpty || forceRefresh) {
          final temsaUnits = await serv.fetchStatusDevice(isTemsa: true);
          if (temsaUnits != null) {
            temsaUnits.sort((a, b) => a.name.toString().toLowerCase().compareTo(b.name.toString().toLowerCase()));
            localUnitTemsa = temsaUnits;
          }
        }
        combinedNames.addAll(localUnitTemsa.map((u) => u.name.toString()));
      }

      _units = combinedNames.toSet().toList(); // Unique
      _units.sort();
      notifyListeners();
    } catch (e) {
      debugPrint("[ ERR ] LOAD EXTERNAL UNITS: ${e.toString()}");
    }
  }
  // endregion BTN SHEET NEW TICKET VIEW

  // region BTN SHEET START JOB TICKET VIEW
  final formKeyStartJob = GlobalKey<FormState>();
  TextEditingController descriptionStartController = TextEditingController();
  TextEditingController lectorasController = TextEditingController(text: "Cargando lectoras...");
  TextEditingController panicoController = TextEditingController(text: "Cargando botón...");
  final ScreenshotController screenshotController = ScreenshotController();


  List<Map<String, String>> evidencePhotos = [];
  bool _isDownloadEnabled = false;
  bool get isDownloadEnabled => _isDownloadEnabled;
  bool isLoadingStart = false;

  void resetEvidenceStart() {
    evidencePhotos = [];
    descriptionStartController.clear();
    lectorasController.text = "Cargando lectoras...";
    panicoController.text = "Cargando botón...";
    _isDownloadEnabled = false;
    isValidateComponent = false;
    isEvidenceUnitUserStart = false;
    urlImgComponent = null;
    urlImgMaps = null;
    isNearUnit = false;
    currentDistance = 0.0;
    userLat = null;
    userLon = null;
    notifyListeners();
  }


  Future<Map<String, dynamic>> getStatusDevice({required int idDevice}) async{
    RequestServ ser = RequestServ.instance;
    try{
      final resp = await ser.fetchStatusDeviceById(deviceId: idDevice);
      return resp as Map<String, dynamic>;
    }catch(e){
      debugPrint("[ ERR ] GET STATUS DEVICE: ${e.toString()}");
    }

    return {
      "name": "error",
    };

  }

  Future<Map<String, dynamic>> getPositionDevice({required int idDevice}) async {
    RequestServ ser = RequestServ.instance;

    try {
      final resp = await ser.fetchByUnit(deviceId: idDevice);

      return resp as Map<String, dynamic>;

    } catch (e) {
      debugPrint("[ ERR ] GET POSITION DEVICE: ${e.toString()}");
    }

    return {
      "error": "error",
      "valid": false,
      "latitude": 0.0,
      "longitude": 0.0,
      "attributes": {"ignition": false, "battery": 0.0}
    };
  }

  // endregion BTN SHEET START JOB TICKET VIEW

  // region BTN SHEET CLOSE JOB TICKET VIEW
  final formKeyCloseJob = GlobalKey<FormState>();
  TextEditingController descriptionCloseController = TextEditingController();
  TextEditingController unitModelCloseController = TextEditingController();
  final ScreenshotController screenshotCloseController = ScreenshotController();
  List<Map<String, String>> evidenceClosePhotos = [];
  bool isEvidenceUnitUserClose = false;
  bool isEvidenceUnitUserStart = false;
  bool isLoadingClose = false;

  // evidence components — states: idle/selected/uploading/pending/approved/rejected
  Map<String, ComponentStatus> componentStatuses = {};
  Map<String, String> componentImageUrls = {};


  void resetEvidenceClose() {
    evidenceClosePhotos = [];
    descriptionCloseController.clear();
    unitModelCloseController.clear();
    lectorasController.text = "Cargando lectoras...";
    panicoController.text = "Cargando botón...";
    _isDownloadEnabled = false;
    isValidateComponent = false;
    isEvidenceUnitUserClose = false;
    urlImgComponent = null;
    urlImgMaps = null;
    isNearUnit = false;
    currentDistance = 0.0;
    userLat = null;
    userLon = null;
    componentStatuses = {};
    componentImageUrls = {};
    notifyListeners();
  }
  // endregion BTN SHEET CLOSE JOB TICKET VIEW

  // region SOCKET
  bool isValidateComponent = false;
  String? urlImgComponent;
  String? urlImgMaps;
  bool isNearUnit = false;
  double currentDistance = 0.0;
  double? userLat;
  double? userLon;
  // endregion SOCKET

  // region COMPONENT EVIDENCE

  /// Returns true when every component that was selected (non-idle) is approved.
  bool get allSelectedComponentsApproved {
    final nonIdle = componentStatuses.values
        .where((s) => s != ComponentStatus.idle)
        .toList();
    if (nonIdle.isEmpty) return true; // ninguno seleccionado → se permite avanzar
    return nonIdle.every((s) => s == ComponentStatus.approved);
  }

  /// Handles a tap on a component button.
  /// [componentName] uses API strings (VCC, GND, IGNITION, GPS, UNIT_ASSEMBLY, p_extra1, p_extra2).
  Future<void> handleComponentTap(
    String componentName,
    String ticketId,
    BuildContext context,
  ) async {
    final current = componentStatuses[componentName] ?? ComponentStatus.idle;

    // 1. Si está aprobado, mostrar la imagen
    if (current == ComponentStatus.approved) {
      final url = componentImageUrls[componentName];
      if (url != null && context.mounted) {
        _showImagePreview(context, componentName, url);
      }
      return;
    }

    // 2. Si está subiendo o pendiente, no hacer nada
    if (current == ComponentStatus.uploading ||
        current == ComponentStatus.pending) {
      return;
    }

    // 3. Abrir cámara directamente
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    componentStatuses[componentName] = ComponentStatus.uploading;
    notifyListeners();

    // Upload image file
    final imageUrl = await uploadPhoto(pickedFile.path);
    if (imageUrl == null) {
      componentStatuses[componentName] = ComponentStatus.selected;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al subir la imagen, intenta de nuevo.')),
        );
      }
      return;
    }

    // Register in BD
    final saved = await saveComponentEvidence(
      ticketId: ticketId,
      componentName: componentName,
      imageUrl: imageUrl,
    );

    componentStatuses[componentName] =
        saved ? ComponentStatus.pending : ComponentStatus.selected;
    notifyListeners();
  }

  /// POST /tickets/{ticketId}/component-evidence
  Future<bool> saveComponentEvidence({
    required String ticketId,
    required String componentName,
    required String imageUrl,
  }) async {
    try {
      final uri =
          Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/component-evidence')
              .replace(queryParameters: {
        'modifierId': UserSession().idUser.toString(),
      });
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'componentName': componentName,
              'imageUrl': imageUrl,
              'status': 'ACTIVO',
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[ ERR ] saveComponentEvidence: $e');
      return false;
    }
  }

  void _showImagePreview(BuildContext context, String title, String url) {
    final resolvedUrl = _resolveImageUrl(url);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  resolvedUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white, size: 50),
                          SizedBox(height: 10),
                          Text('No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Remove /api/ if present in baseUrlNor to get the root
    String base = RequestServ.baseUrlNor;
    if (base.endsWith('/api/')) {
      base = base.substring(0, base.length - 5);
    } else if (base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }

    // Ensure base ends with / if path doesn't start with /
    // Or remove trailing / from base if path starts with /
    if (base.endsWith('/') && path.startsWith('/')) {
      base = base.substring(0, base.length - 1);
    } else if (!base.endsWith('/') && !path.startsWith('/')) {
      base = '$base/';
    }

    return '$base$path';
  }

  /// GET /tickets/{ticketId}/component-evidence — polls admin validation status.
  Future<void> pollComponentStatuses(String ticketId) async {
    try {
      final uri = Uri.parse(
          '${RequestServ.baseUrlNor}tickets/$ticketId/component-evidence');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final List<dynamic> list = jsonDecode(response.body);
      bool changed = false;

      for (final item in list) {
        final name = item['componentName'] as String?;
        final status = (item['status'] as String? ?? '').toUpperCase();
        final imageUrl = item['imageUrl'] as String?;
        if (name == null) continue;

        if (imageUrl != null) {
          componentImageUrls[name] = imageUrl;
        }

        final current = componentStatuses[name] ?? ComponentStatus.idle;
        // Only update if we are waiting for admin (pending)
        if (current == ComponentStatus.pending ||
            current == ComponentStatus.selected ||
            current == ComponentStatus.rejected) {
          ComponentStatus next;
          if (status == 'VALIDADA' || status == 'APROBADO') {
            next = ComponentStatus.approved;
          } else if (status == 'RECHAZADO') {
            next = ComponentStatus.rejected;
          } else {
            continue;
          }
          componentStatuses[name] = next;
          changed = true;
        }
      }

      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('[ ERR ] pollComponentStatuses: $e');
    }
  }

  // endregion COMPONENT EVIDENCE

  /*================ FUNCTIONS =================*/

  // region TICKET VIEW
  Future<void> loadTickets()async{
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final serv = RequestServ.instance;

    try{

      String formatDateForApi(String dateStr) {
        if (dateStr.isEmpty || !dateStr.contains('/')) return dateStr;
        List<String> parts = dateStr.split('/');
        if (parts.length != 3) return dateStr;

        return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
      }

      Map<String, dynamic> data = {
        "start_date": formatDateForApi(controllerDateStart.text),
        "end_date": formatDateForApi(controllerDateEnd.text),
      };

      List<ApiResTicket>? ticketsRecuperados = await serv.handlingRequestParsed<List<ApiResTicket>>(
        urlParam: RequestServ.urlGetTickets,
        params: data,
        asJson: true,
        fromJson: (json) {
          final list = json as List<dynamic>;
          return list.map((item) => ApiResTicket.fromJson(item)).toList();
        },
      );

      _tickets = ticketsRecuperados ?? [];

      final String currentBranch = UserSession().branchRoot.toUpperCase().trim();

      _units = _tickets
          .where((t) => (t.company ?? '').toUpperCase().trim() == currentBranch)
          .map((t) => t.unitId)
          .toSet()
          .toList();

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
      debugPrint("[ ERR ] LOAD TICKETS: $e");
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
    Future<ApiResTicket?> createTicket({required BuildContext context, bool isUpdate = false, int? idTicket, bool shouldPop = true}) async{

      if (!formKey.currentState!.validate()) {
        AnimatedResultDialog.showError(
            context,
            title: "Campos incompletos",
            message: "Es necesario agregar una descripciòn"
        );
        return null;
      }

      if (installerController.text.isEmpty && installerId == 0 ) {
        AnimatedResultDialog.showError(
            context,
            title: "Campos incompletos",
            message: "Es necesario agregar un instalador"
        );
        return null;
      }

      if (unitController.text.isEmpty) {
        AnimatedResultDialog.showError(
            context,
            title: "Campos incompletos",
            message: "Es necesario agregar una unidad"
        );
        return null;
      }

      final serv = RequestServ.instance;

      try{
        String url = isUpdate? "${RequestServ.urlGetTickets}/$idTicket":"${RequestServ.urlGetTickets}/";
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

        ApiResTicket? ticket = await serv.handlingRequestParsed<ApiResTicket>(
          urlParam: url,
          params: param,
          method: method,
          asJson: true,
          fromJson: (json) => ApiResTicket.fromJson(json),
        );

        if(ticket == null) return null;

        if (shouldPop) {
          loadTickets();
          if (context.mounted) Navigator.pop(context);
          _isLoading = false;
          resetForm();
          notifyListeners();
        }

        return ticket;

      }catch(e){
        debugPrint("[ ERROR ] CREATE TICKET => ${e.toString()}");
        return null;
      }
    }

    /// METODOLOGÍA COMBINADA SOLICITADA
    Future<void> createTicketCombined({required BuildContext context, bool isUpdate = false, int? idTicket}) async {
      _isLoading = true;
      notifyListeners();

      // 1. Primero se crea el nuevo ticket como ya esta
      ApiResTicket? ticket = await createTicket(context: context, isUpdate: isUpdate, idTicket: idTicket, shouldPop: false);
      
      if(ticket == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Si tiene imagenes en el arreglo de "evidencia antes" llamar metodologia que se tiene en @start_job_ticket.dart
      if (evidencePhotos.isNotEmpty) {
        descriptionStartController.text = descriptionController.text;
        await sendEvidence(context: context, idTicket: ticket.id, ticket: ticket, shouldPop: false);
      }

      // 3. Lo mismo para el de cierre, llama la metodologia de @close_job_ticket.dart
      if (evidenceClosePhotos.isNotEmpty) {
        descriptionCloseController.text = descriptionController.text;
        await sendEvidenceClose(context: context, idTicket: ticket.id, ticket: ticket, shouldPop: false);
      }

      loadTickets();
      if (context.mounted) Navigator.pop(context);
      _isLoading = false;
      resetForm();
      disconnectSocket();
      notifyListeners();
    }
  // endregion BTN SHEET NEW TICKET VIEW

  // region GET INSTALLER
    Future<void> getInstaller({bool forceRefresh = false}) async {
      if (_installers.isNotEmpty && !forceRefresh) return;

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
        debugPrint("[ ERR ] GET INSTALLER: ${e.toString()}");
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
        debugPrint("[ ERROR ] DELETE TICKET ${e.toString()}");
      }
    }

    Future<bool> deleteTicketTest({
      required int ticketId,
      required String modifierId,
      required String updatedByName,
      String? reason,
    }) async {

      String urlNew = "${RequestServ.baseUrlNor}${RequestServ.urlGetTickets}/$ticketId";

      final Uri url = Uri.parse(urlNew).replace(
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

          return true;
        } else {
          debugPrint('Error al eliminar ticket');
          debugPrint('Status: ${response.statusCode}');
          debugPrint('Body: ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('Exception deleteTicket: $e');
        return false;
      }
    }
  // endregion BTN DELETE TICKET VIEW

  // region BTN SHEET START JOB TICKET VIEW
    Future<void> sendEvidence({required BuildContext context, int? idTicket, ApiResTicket? ticket, bool shouldPop = true}) async{

      if (shouldPop && !formKeyStartJob.currentState!.validate()) return;

      if( evidencePhotos.length < 2 ) {
        if (shouldPop) {
          AnimatedResultDialog.showError(
              context,
              title: "No hay evidencias",
              message: "Por lo menos una foto es requerida"
          );
        }
        return;
      }

      // return;
      print("=> ${evidencePhotos.length}");

      try{

        List<Map<String, dynamic>> photosToSync = [];
        for (int i = 0; i < evidencePhotos.length; i++) {
          photosToSync.add({
            'path': evidencePhotos[i]['path'],
            'url': null,
            'synced': 0,
            'sequence': i + 1
          });
        }

        final job = OfflineSyncJob(
          ticketId: idTicket.toString(),
          type: 'START',
          observations: descriptionStartController.text,
          technicianName: ticket?.technicianName ?? '',
          unitId: ticket?.unitId ?? '',
          timestamp: DateTime.now().toIso8601String(),
          changedBy: UserSession().nameUser,
          phase: "PROCESO",
          photosJson: jsonEncode(photosToSync),
        );

        await OfflineSyncService.instance.saveJob(job);

        _triggerSync();

        if (shouldPop) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Guardado correctamente. Se sincronizará en segundo plano.')),
            );
          }
          
          loadTickets();
          _isLoading = false;
          if (context.mounted) Navigator.pop(context); 
          disconnectSocket();
          notifyListeners();
        }

      }catch(e){
        debugPrint("[ ERROR ] START JOB ACTIVITY ${e.toString()}");
      }
    }

  // endregion BTN SHEET START JOB TICKET VIEW

  // region BTN SHEET CLOSE JOB TICKET VIEW
  Future<void> sendEvidenceClose({required BuildContext context, int? idTicket, ApiResTicket? ticket, bool shouldPop = true}) async{

    if (shouldPop && !formKeyCloseJob.currentState!.validate()) return;

    if( evidenceClosePhotos.length < 2 ) {
      if (shouldPop) {
        AnimatedResultDialog.showError(
            context,
            title: "No hay evidencias",
            message: "Por lo menos una foto es requerida"
        );
      }
      return;
    }

    // return; // Se asume que esto estaba para pruebas, pero lo dejo por si acaso o lo comento si estorba
    try{

      List<Map<String, dynamic>> photosToSync = [];
      for (int i = 0; i < evidenceClosePhotos.length; i++) {
        photosToSync.add({
          'path': evidenceClosePhotos[i]['path'],
          'url': null,
          'synced': 0,
          'sequence': i + 1
        });
      }

      final job = OfflineSyncJob(
        ticketId: idTicket.toString(),
        type: 'CLOSE',
        observations: descriptionCloseController.text,
        technicianName: ticket?.technicianName ?? '',
        unitId: ticket?.unitId ?? '',
        timestamp: DateTime.now().toIso8601String(),
        changedBy: UserSession().nameUser,
        phase: "PENDIENTE_VALIDACION",
        photosJson: jsonEncode(photosToSync),
      );

      await OfflineSyncService.instance.saveJob(job);

      _triggerSync();

      if (shouldPop) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardado correctamente. Se sincronizará en segundo plano.')),
          );
        }

        loadTickets();
        _isLoading = false;
        if (context.mounted) Navigator.pop(context);
        disconnectSocket();
        notifyListeners();
      }
    }catch(e){
      debugPrint("[ ERROR ] CLOSE JOB ACTIVITY ${e.toString()}");
    }
  }

  void _triggerSync() {
    OfflineSyncService.instance.syncEverything();
  }
  // endregion BTN SHEET CLOSE JOB TICKET VIEW

  // region SOCKET
  void initSocket(String idTicket, String company) {
    lectorasController.text = "Buscando unidad...";
    panicoController.text = "Buscando unidad...";
    _socket.onUnitUpdate = (data) {
      _updateUnitPosition(data, idTicket);
    };

    _socket.connect( company );
  }

  Future<void> _updateUnitPosition(Map<String, dynamic> data, String idTicket) async {

    if (!data.containsKey('positions')) return;

    final positions = data['positions'];
    if (positions is! List || positions.isEmpty) return;

    final pos = positions.first;
    final deviceId = pos['deviceId'] as int;
    print("deviceId => $deviceId==${int.parse(idTicket)} | ${deviceId == int.parse(idTicket)}");
    if( deviceId == int.parse(idTicket) ){

      _isDownloadEnabled = true;
      notifyListeners();
      print("data socket => $pos");
      print("device id socket => $deviceId | search id => $idTicket => ${deviceId == int.parse(idTicket)}");
      bool btnPanicEventOne = pos["attributes"]["di2"] != "null" && pos["attributes"]["di2"] == "true" ;
      bool btnPanicEventTwo = pos["attributes"]["in2"] != "null" && pos["attributes"]["in2"] == "true" ;
      print("${pos["attributes"]["di2"]} $btnPanicEventOne");
      print("${pos["attributes"]["in2"]} $btnPanicEventTwo");
      print("${btnPanicEventOne || btnPanicEventTwo}");

      panicoController.text = btnPanicEventOne || btnPanicEventTwo? "Verificación correcta" :"Esperando evento...";

      // region reds
      print("reds => ${pos["attributes"]["event"]}");
      print(pos["attributes"]["event"] == "207");
      bool isRead = pos["attributes"]["event"] != "null" && pos["attributes"]["event"] == "207";
      // print("isRead => $isRead");
      lectorasController.text = isRead? "Verificación correcta" :"Esperando evento...";
      // region reds
    }

  }

  void disconnectSocket() {
    _socket.disconnect();
    // Limpiamos los textos al desconectar para que no queden valores viejos
    lectorasController.text = "Cargando lectoras...";
    panicoController.text = "Cargando botón...";
    _isDownloadEnabled = false;
    notifyListeners();
  }
  // endregion SOCKET

  // region UTILITIES
  // 1.
  Future<void> updateStatus(String ticketId, String status, String changedBy) async {
    // print("url => ${RequestServ.baseUrlNor}tickets/$ticketId/status");
    await http.put(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'status': status,
        'changedBy': changedBy,
      }),
    );
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
    await http.post(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/evidence'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'imageUrl': imageUrl,
        'phase': phase,
        'sequence': sequence,
      }),
    );
  }

  // 4.
  Future<void> sendFormData(String ticketId, String formType, Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('${RequestServ.baseUrlNor}tickets/$ticketId/form-data'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'formType': formType,
        'data': data,
      }),
    );
  }

  Future<void> takeScreenshotAndSaveMaps( bool isClose ) async {
    try {
      final controller = isClose ? screenshotCloseController : screenshotController;
      final image = await controller.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/validate_maps_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(image);

      // Guardamos la ruta con el origen SCREENSHOT_MAPS
      if (isClose) {
        evidenceClosePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_MAPS');
        evidenceClosePhotos.add({"path": filePath, "source": "SCREENSHOT_MAPS"});
        isEvidenceUnitUserClose = true;
      } else {
        evidencePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_MAPS');
        evidencePhotos.add({"path": filePath, "source": "SCREENSHOT_MAPS"});
        isEvidenceUnitUserStart = true;
      }
      urlImgMaps = filePath;

      notifyListeners();
    } catch (e) {
      debugPrint("Error capturing screenshot: $e");
    }
  }

  Future<void> takeScreenshotAndSave( bool isClose ) async {
    try {
      final controller = isClose ? screenshotCloseController : screenshotController;
      final image = await controller.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/validate_comp_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(image);

      // Guardamos la ruta con el origen SCREENSHOT_COMPONENTS
      if (isClose) {
        evidenceClosePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_COMPONENTS');
        evidenceClosePhotos.add({"path": filePath, "source": "SCREENSHOT_COMPONENTS"});
      } else {
        evidencePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_COMPONENTS');
        evidencePhotos.add({"path": filePath, "source": "SCREENSHOT_COMPONENTS"});
      }
      isValidateComponent = true;
      urlImgComponent = filePath;

      notifyListeners();
    } catch (e) {
      debugPrint("Error capturing screenshot: $e");
    }
  }

  void clearValidation(bool isClose) {
    if (isClose) {
      evidenceClosePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_COMPONENTS');
      evidenceClosePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_MAPS');
      isEvidenceUnitUserClose = false;
    } else {
      evidencePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_COMPONENTS');
      evidencePhotos.removeWhere((img) => img['source'] == 'SCREENSHOT_MAPS');
      isEvidenceUnitUserStart = false;
    }
    urlImgComponent = null;
    urlImgMaps = null;
    isValidateComponent = false;
    isNearUnit = false;
    currentDistance = 0.0;
    userLat = null;
    userLon = null;
    notifyListeners();
  }

  Future<void> checkProximity(double unitLat, double unitLon) async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('=> Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('=> Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('=> Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      debugPrint('=> hola');

      // 1. Intentamos obtener la última posición conocida primero (es instantáneo)
      Position? position = await Geolocator.getLastKnownPosition();
      
      try {
        // 2. Intentamos obtener la posición actual con un TIMEOUT de 5 segundos
        // Usamos Accuracy medium ya que es más rápido y suficiente para 20 metros
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint("=> ⚠️ Timeout o error obteniendo posición actual, usando última conocida si existe: $e");
        // Si falló el actual, nos quedamos con la que obtuvimos en el paso 1
      }

      if (position != null) {
        userLat = position.latitude;
        userLon = position.longitude;
        currentDistance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          unitLat,
          unitLon,
        );
      } else {
        debugPrint("=> ❌ No se pudo obtener ninguna posición (actual ni conocida).");
      }

      debugPrint("------------------------------------------");
      debugPrint("=> 📍 DISTANCIA A LA UNIDAD: ${currentDistance.toStringAsFixed(2)} metros");
      debugPrint("------------------------------------------");

      isNearUnit = currentDistance <= 15.0;
      // isNearUnit = currentDistance >= 8000.0 && currentDistance <= 15000.0;
      notifyListeners();
    } catch (e) {
      debugPrint("=> ❌ Error crítico en checkProximity: $e");
    }
  }
  // endregion UTILITIES

}
