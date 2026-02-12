import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'response_service.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  SharedPreferences? _prefs;

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get isLogin => _prefs?.getBool('isLogin') ?? false;
  set isLogin(bool value) => _prefs?.setBool('isLogin', value);

  // region persist data user

  bool get isMaster => _prefs?.getBool('isMaster') ?? false;
  set isMaster(bool value) => _prefs?.setBool('isMaster', value);

  String get branchRoot => _prefs?.getString('branchRoot') ?? 'BUSMEN';
  set branchRoot(String value) => _prefs?.setString('branchRoot', value);

  String get nameUser => _prefs?.getString('nameUser') ?? '';
  set nameUser(String value) => _prefs?.setString('nameUser', value);

  int get idUser => _prefs?.getInt('idUser') ?? 0;
  set idUser(int value) => _prefs?.setInt('idUser', value);


  // Limpiar datos
  Future<void> clear() async {
    // _prefs?.remove("userData");
    // _prefs?.remove("companyData");
    isLogin = false;
    isMaster = false;
    branchRoot = "BUSMEN";
    nameUser = "";
    idUser = 0;
  }
}
