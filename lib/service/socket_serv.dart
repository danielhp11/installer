import 'package:instaladores_new/service/request_service.dart';
import 'package:instaladores_new/service/user_session_service.dart';

import 'dart:convert';
import 'dart:io';

class SocketServ {
  static final SocketServ instance = SocketServ._();
  SocketServ._();

  WebSocket? _ws;
  String? _cookie;
  bool _intentionalDisconnect = false;

  Function(Map<String, dynamic> data)? onUnitUpdate;

  Future<void> loadSession(bool isBusmen) async {
    final serv = RequestServ.instance;
    _cookie = await serv.sessionGeovoySistem(isBusmen);
  }

  Future<void> connect(String company) async {
    if (_ws != null) return;

    _intentionalDisconnect = false;

    if (_cookie == null) {
      await loadSession( company.toUpperCase() == "BUSMEN" );
      if (_cookie == null) return;
    }
    // "wss://rastreotemsa.geovoy.com/api/socket"
    final uri = company.toUpperCase() == "BUSMEN"? Uri.parse("wss://rastreobusmen.geovoy.com/api/socket"):
    Uri.parse("wss://rastreotemsa.geovoy.com/api/socket");

    try {

      _ws = await WebSocket.connect(
        uri.toString(),
        headers: {
          "Cookie": _cookie!,
        },
      );


      _ws!.listen(
            (message) {
          try {
            if (message == null || message.toString().trim().isEmpty) {
              print("WS => mensaje vacío o null");
              return;
            }

            final dynamic data = jsonDecode(message);

            if (!hasPositions(data)) {
              return;
            }


            if (data is! Map<String, dynamic>) {
              print("WS => mensaje no es un objeto Map, recibido: $data");
              return;
            }

            if (onUnitUpdate != null) {
              onUnitUpdate!(data);
            }
          } catch (e) {
            print("ERROR PARSEANDO JSON => $e");
            print("MENSAJE RECIBIDO => $message");
          }
        },

        onDone: () {

          _ws = null;
          if (!_intentionalDisconnect) {
            reconnect(company);
          }
        },

        onError: (error) {
          print("ERROR EN WS => $error");
          _ws = null;
          if (!_intentionalDisconnect) {
            reconnect(company);
          }
        },
      );

    } catch (e) {
      print("ERROR AL CONECTAR WS => $e");
      if (!_intentionalDisconnect) {
        reconnect(company);
      }
    }
  }

  /// Intentos automáticos cada 3 segundos
  void reconnect(String company) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_intentionalDisconnect) return;
      print("Reintentando conexión WebSocket...");
      connect(company);
    });
  }

  void disconnect() {
    print("Cerrando WebSocket...");
    _intentionalDisconnect = true;
    _ws?.close();
    _cookie = null;
    _ws = null;
  }

  bool hasPositions(Map<String, dynamic> data) {
    return data.containsKey('positions') &&
        data['positions'] is List &&
        (data['positions'] as List).isNotEmpty;
  }

}
