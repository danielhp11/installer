import 'package:flutter/cupertino.dart';
import 'package:instaladores_new/service/request_service.dart';

import '../service/response_service.dart';

class EvidenceStartFinishViewmodel extends ChangeNotifier {

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late List<ItemEvidence> _evidenceStart;
  List<ItemEvidence> get evidenceStart => _evidenceStart;

  late List<ItemEvidence> _evidenceClose;
  List<ItemEvidence> get evidenceClose => _evidenceClose;


  @override
  void dispose() {
    super.dispose();
  }

  void resetModel(){
    _isLoading = false;
    _evidenceStart = [];
    _evidenceClose = [];
  }

  // region
  // endregion

  // region PROCESO = INICIO PENDIENTE_VALIDACION= FIN
  void initSeparateEvidence(List<ItemEvidence> evidence){
    _evidenceStart = [];
    _evidenceClose = [];

    evidence.forEach((things) {
      if(things.phase.toUpperCase() == "PROCESO"){
        _evidenceStart.add(things);
      }else{
        _evidenceClose.add(things);
      }

    });


    notifyListeners();
  }
  // endregion

}