import 'package:flutter/material.dart';
import 'package:instaladores_new/service/user_session_service.dart';
import 'package:instaladores_new/view/list_ticket_view.dart';
import 'package:instaladores_new/viewModel/list_ticket_viewmodel.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'view/login_view.dart';
import 'viewModel/login_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UserSession().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ListTicketViewmodel())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tickets',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: UserSession().isLogin ? const ListTicketView() : const LoginView(),
    );
  }
}
