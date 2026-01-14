import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestServ {
  // static const String baseUrlAdm = "";
  static const String baseUrlNor = "http://172.16.2.147:8000/";

  static const String urlAuthentication = "auth/login";


  // Singleton pattern
  RequestServ._privateConstructor();
  static final RequestServ instance = RequestServ._privateConstructor();

  Future<String?> handlingRequest({
    required String urlParam,
    Map<String, dynamic>? params,
    String method = "GET",
    bool asJson = false,
    urlFull = false
  }) async {
    try {
      // Decide base URL
      // bool isNormUrl = urlParam == urlValidateUser ||
      //     urlParam == urlGetRoute ||
      //     urlParam == urlStopInRoute ||
      //     urlParam == urlUnitAsiggned;

      final base = baseUrlNor; //isNormUrl ? baseUrlNor : baseUrlAdm;
      String fullUrl = urlFull? urlParam :base + urlParam;

      http.Response response;
      // print("=> $fullUrl");
      // Agregar parámetros para GET en query string
      if (method.toUpperCase() == 'GET' && params != null && params.isNotEmpty) {
        final uri = Uri.parse(fullUrl).replace(queryParameters: params);
        response = await http.get(uri).timeout(const Duration(seconds: 10));
      } else {
        // Construir el body según asJson o form-url-encoded
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
            response = await http
                .post(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PUT':
            response = await http
                .put(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PATCH':
            response = await http
                .patch(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'DELETE':
            response = await http
                .delete(uri, body: body, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          default:
            throw UnsupportedError("HTTP method $method no soportado");
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        print("HTTP error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error en handlingRequest: $e");
      return null;
    }
  }

  /// Función genérica para parsear JSON a objeto
  Future<T?> handlingRequestParsed<T>(
      {required String urlParam,
        Map<String, dynamic>? params,
        String method = "GET",
        bool asJson = false,
        required T Function(dynamic json) fromJson, urlFull = false} ) async {
    final responseString = await handlingRequest(
        urlParam: urlParam, params: params, method: method, asJson: asJson, urlFull: urlFull);

    if (responseString == null) return null;

    try {
      final jsonMap = jsonDecode(responseString);
      return fromJson(jsonMap);
    } catch (e) {
      print("Error parseando JSON: $e");
      return null;
    }
  }
}
