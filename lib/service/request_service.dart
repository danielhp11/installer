import 'dart:convert';
import 'package:http/http.dart' as http;
import 'response_service.dart';

class RequestServ {
  static bool isDebug = true;

  static String baseUrlNor = isDebug? "http://172.16.2.147:8000/" : "https://instaladores.geovoy.com/api/";

  static const String urlAuthentication = "auth/login";
  static const String urlGetTickets = "tickets/";
  static const String urlInstaller = "users/?all=false";
  static const String urlSendStartJobEvidence = "tickets/upload";


  static const String _apiUser = 'apinstaladores@geovoy.com';
  static const String _apiPass = 'Instaladores*9';

  final String basicAuth =
      'Basic ${base64Encode(utf8.encode('$_apiUser:$_apiPass'))}';

  RequestServ._privateConstructor();
  static final RequestServ instance = RequestServ._privateConstructor();

  Future<String?> handlingRequest({ required String urlParam, Map<String, dynamic>? params, String method = "GET", bool asJson = false, urlFull = false, }) async {
    try {
      final base = baseUrlNor;

      String fullUrl = urlFull ? urlParam : base + urlParam;

      http.Response response;
      if (isDebug){
        print("<=================================================================================================================================>");
        print("[ $method ] url => $fullUrl");
        print("[ $method ] params => $params");
        print("<=================================================================================================================================>");
      }

      if (method.toUpperCase() == 'GET') {
        // Si es GET, arma la URL con o sin parámetros
        Uri uri;
        if (params != null && params.isNotEmpty) {
          uri = Uri.parse(fullUrl).replace(queryParameters: params);
        } else {
          uri = Uri.parse(fullUrl);
        }
        response = await http.get(uri).timeout(const Duration(seconds: 10));
      } else {
        // Para otros métodos, construye body y headers
        dynamic body;
        Map<String, String>? headers;

        if (params != null) {
          if (asJson) {
            body = jsonEncode(params);
            headers = {'Content-Type': 'application/json'};
          } else {
            body = params.map((k, v) => MapEntry(k, v.toString()));
            headers = {'Content-Type': 'application/x-www-form-urlencoded'};
          }
        }

        Uri uri = Uri.parse(fullUrl);

        switch (method.toUpperCase()) {
          case 'POST':
            response = await http.post(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PUT':
            response = await http.put(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PATCH':
            response = await http.patch(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'DELETE':
            response = await http.delete(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          default:
            throw UnsupportedError("HTTP method $method no soportado");
        }
      }
      if( RequestServ.isDebug ){
        print("<=================================================================================================================================>");
        print("[ $method ] response => ${response.body}");
        print("<=================================================================================================================================>");
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if( RequestServ.isDebug ){
          print("<=================================================================================================================================>");
          print("[ $method ] response.body => ${response.body}");
          print("<=================================================================================================================================>");
        }
        return response.body;
      } else {
        print("HTTP error: ${response.statusCode}");
        print("response => ${response.headers}");
        return null;
      }
    } catch (e) {
      print("Error en handlingRequest: $e");
      return null;
    }
  }

  /// Función genérica para parsear JSON a objeto
  Future<T?> handlingRequestParsed<T>( { required String urlParam, Map<String, dynamic>? params, String method = "GET", bool asJson = false, required T Function(dynamic json) fromJson, urlFull = false} ) async {
    final responseString = await handlingRequest(
        urlParam: urlParam, params: params, method: method, asJson: asJson, urlFull: urlFull);

    if (responseString == null) return null;

    try {
      final jsonMap = jsonDecode(responseString);
      if( RequestServ.isDebug ){
        print("<=================================================================================================================================>");
        print("[ $method ] handlingRequestParsed | jsonMap => $jsonMap");
        print("<=================================================================================================================================>");
      }
      return fromJson(jsonMap);
    } catch (e) {
      print("Error parseando JSON: $e");
      return null;
    }
  }


// region Units
  Future<List<dynamic>?> fetchStatusDevice({bool isTemsa = false }) async {

    try {
      final url = isTemsa? Uri.parse("https://rastreotemsa.geovoy.com/api/devices") :Uri.parse("https://rastreobusmen.geovoy.com/api/devices");

      final response = await http.get(
        url,
        // headers: {"Cookie": cookie},
        headers: {"Authorization": basicAuth},
      );

      if (response.statusCode != 200) {
        print("HTTP error: ${response.statusCode}");
        return null;
      }

      final List<dynamic> jsonBody = jsonDecode(response.body);
      if( isDebug ){
        print("[ GET ] url => $url");
        print("[ GET ] jsonBody => $jsonBody");
        print("[ GET ] headers => Authorization:$basicAuth");
      }
      
      if (isTemsa) {
        return jsonBody.map((item) => UnitTemsa.fromJson(item)).toList();
      } else {
        return jsonBody.map((item) => UnitBusmen.fromJson(item)).toList();
      }

    } catch (e) {
      print("Error fetchStatusForUnit: $e");
      return null;
    }
  }
// endregion Units

  // region Installer COOKIE
  Future<String?> sessionGeovoySistem(bool isBusmen) async {
    try {
      var client = http.Client();
      // https://rastreotemsa.geovoy.com
      String url = isBusmen? "https://rastreobusmen.geovoy.com/api/session":"https://rastreotemsa.geovoy.com/api/session" ;

      var response = await client.post(
        Uri.parse(url),
        body: {
          // "email": "usuariosapp",
          // "password": "usuarios0904",
          "email": "desarrollo@geovoy.com",
          "password": "DesGeo122",
        },
      );

      if (response.statusCode != 200) {
        print("Error: ${response.statusCode}");
        return null;
      }

      String? rawCookie = response.headers['set-cookie'];

      if (rawCookie != null) {
        String? parsedCookie = rawCookie.split(";").first;
        // UserSession.token = parsedCookie;
        if( isDebug ){
          print("[ POST ] cookie url => $url");
          print("[ POST ] cookie parms => ${
              {"email": "desarrollo@geovoy.com",
                "password": "DesGeo122"}
              }");
          print("[ POST ] cookie response => $rawCookie");
        }

        return parsedCookie;
      }

      return null;

    } catch (e) {
      print("Error sessionGeovoySistem: $e");
      return null;
    }
  }
  // region Installer COOKIE


  // region device position
  Future<Map<String, dynamic>?> fetchByUnit( { required int deviceId }) async {
    try {
      final url = Uri.parse("https://rastreobusmen.geovoy.com/api/positions");

      final response = await http.get(
        url,
        // headers: {"Cookie": cookie},
        headers: {"Authorization": basicAuth},
      );

      if (response.statusCode != 200) {
        print("HTTP error: ${response.statusCode}");
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(response.body);

      if( isDebug ){
        print("[ GET ] url => $url");
        print("[ GET ] jsonList => $jsonList");
        print("[ GET ] headers => Authorization:$basicAuth");
      }

      final pos = jsonList.cast<Map<String, dynamic>>().firstWhere(
            (p) => p["deviceId"] == deviceId,
        orElse: () => {},
      );

      if (pos.isEmpty) {
        print("No se encontró posición para deviceId $deviceId");
        return null;
      }

      return pos;

    } catch (e) {
      print("Error fetchByUnit: $e");
      return null;
    }
  }
  // endregion device position

  // region device status
  Future<dynamic> fetchStatusDeviceById({ required int deviceId }) async {
    try {
      final url = Uri.parse("https://rastreobusmen.geovoy.com/api/devices/$deviceId");

      final response = await http.get(
        url,
        // headers: {"Cookie": cookie},
        headers: {"Authorization": basicAuth},
      );

      if (response.statusCode != 200) {
        print("HTTP error: ${response.statusCode}");
        return null;
      }

      final jsonBody = jsonDecode(response.body);
      if( isDebug ){
        print("[ GET ] url => $url");
        print("[ GET ] jsonBody => $jsonBody");
        print("[ GET ] headers => Authorization:$basicAuth");
      }

      return jsonBody;

    } catch (e) {
      print("Error fetchStatusForUnit: $e");
      return null;
    }
  }

  // endregion device status

}
