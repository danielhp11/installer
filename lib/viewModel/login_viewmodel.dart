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
    notifyListeners();

    final serv = RequestServ.instance;

    bool isLogin = false;
    try{

      ApiResAuthentication? auth = await serv.handlingRequestParsed<ApiResAuthentication>(
          urlParam: RequestServ.urlAuthentication,
          params: {
            "username": email,
            "password": password
          },
          method: "POST",
          asJson: false,
          fromJson: (json) {
            return ApiResAuthentication.fromJson(json); },
      );

      if( auth == null ) return isLogin;

      isLogin = true;
      UserSession().isLogin = isLogin;
      UserSession().isMaster = auth.user_rol;
      UserSession().nameUser = auth.name;
      UserSession().idUser = auth.id;

    }catch(e){
      print(e);
    }finally{
      _isLoading = false;
      notifyListeners();
    }


    return isLogin;
  }
}
