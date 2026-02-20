import 'package:flutter/material.dart';
import 'package:instaladores_new/service/user_session_service.dart';

import '../service/request_service.dart';
import '../service/response_service.dart';

class LoginViewModel extends ChangeNotifier {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool obscurePassword = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final serv = RequestServ.instance;

    bool isLogin = false;
    try{

      // Aseguramos que los valores sean Strings y no tengan espacios extra
      final Map<String, dynamic> loginParams = {
        "username": email.trim(),
        "password": password.trim(),
      };

      if( RequestServ.isDebug ){
        print("<=================================================================================================================================>");
        print("LoginViewModel | Enviando params: $loginParams");
        print("<=================================================================================================================================>");
      }

      ApiResAuthentication? auth = await serv.handlingRequestParsed<ApiResAuthentication>(
          urlParam: RequestServ.urlAuthentication,
          params: loginParams,
          method: "POST",
          asJson: false,
          fromJson: (json) {
            if( RequestServ.isDebug ){
              print("<=================================================================================================================================>");
              print("urlAuthentication | json => $json");
              print("<=================================================================================================================================>");
            }
            return ApiResAuthentication.fromJson(json); 
          },
      );

      if( auth == null ) {
        _errorMessage = "Error de autenticación. Revisa tus credenciales.";
        return isLogin;
      }

      isLogin = true;
      UserSession().isLogin = isLogin;
      UserSession().isMaster = auth.user_rol;
      UserSession().nameUser = auth.name;
      UserSession().idUser = auth.id;

    }catch(e){
      print("<=================================================================================================================================>");
      print("Error en LoginViewModel: $e");
      print("<=================================================================================================================================>");
      _errorMessage = "Ocurrió un error inesperado.";
    }finally{
      _isLoading = false;
      notifyListeners();
    }

    return isLogin;
  }
}
