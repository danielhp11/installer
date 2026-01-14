import 'package:flutter/material.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/view/list_ticket_view.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'view/login_view.dart';
import 'viewModel/login_viewmodel.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  UserSession().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Si el usuario ya está logueado, podrías cambiar LoginView() por ListTicketView() aquí.
    print("isLogin => ${UserSession().isLogin}");

    Widget viewMain = UserSession().isLogin ? const ListTicketView() : const LoginView();

    return MaterialApp(
      title: 'Gestor de Tickets',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: viewMain,
    );
  }
}
