import 'package:flutter/cupertino.dart';

import '../service/request_service.dart';
import '../service/response_service.dart';

class ListTicketViewmodel extends ChangeNotifier {


  bool _isLoading = false;
  String? _errorMessage;
  // region TICKET VIEW
  List<ApiResTicket> _tickets = [];

  List<ApiResTicket> get tickets => _tickets;
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

  @override
  void dispose() {
    super.dispose();
  }

  // region TICKET VIEW
  Future<void> loadTickets()async{
    _isLoading = true;
    _errorMessage = null;

    final serv = RequestServ.instance;

    try{
      _tickets.clear();
      List<ApiResTicket>? tickets = await serv.handlingRequestParsed<List<ApiResTicket>>(
        urlParam: RequestServ.urlGetTickets,
        asJson: true,
        fromJson: (json) {
          final list = json as List<dynamic>;
          return list.map((item) => ApiResTicket.fromJson(item)).toList();
        },
      );

      // tickets?.forEach((element) {
      //   print(element.title);
      // });
      _tickets = tickets ?? [];
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }

  }
// endregion TICKET VIEW

  // region BTN SHEET NEW TICKET VIEW
  // {
  // "title": "",
  // "description": "pruebas de funcionalidad",
  // "priority": "",
  // "category": "",
  // "status": "ABIERTO",
  // "technicianName": "AQUI IRIA EL ID DEL INSTALADOR",
  // "unitId": "ID DE LA UNIDAD",
  // "company": "BUSMEN/TEMSA"
  // }
  Future<void> createticket(BuildContext context) async{

    if (!formKey.currentState!.validate()) return;

    _isLoading = true;
    _errorMessage = null;

    final serv = RequestServ.instance;

    try{
      print("${
      {
        "title": "",
        "description": descriptionController.text,
        "priority": "",
        "category": "",
        "status": "ABIERTO",
        "technicianName": installerController.text,
        "unitId": unitController.text,
        "company": companyController.text.toUpperCase()
      }
      }");

      ApiResTicket? ticket = await serv.handlingRequestParsed<ApiResTicket>(
        urlParam: "${RequestServ.urlGetTickets}/",
        params: {
          "title": "",
          "description": descriptionController.text,
          "priority": "",
          "category": "",
          "status": "ABIERTO",
          "technicianName": installerController.text,
          "unitId": unitController.text,
          "company": companyController.text.toUpperCase()
        },
        method: "POST",
        asJson: true,
        fromJson: (json) => ApiResTicket.fromJson(json),
      );

      if(ticket == null) return;

      print("new ticket =>${ticket}");

      loadTickets();

      Navigator.pop(context);

    }catch(e){
      print("[ ERROR ] CREATE TICKET => ${e.toString()}");
    }
    // finally{
      // notifyListeners();
    // }

  }
  // endregion BTN SHEET NEW TICKET VIEW

}