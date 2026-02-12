import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModel/login_viewmodel.dart';
import 'list_ticket_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);


    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Stack(
       children: [
         // region banner background top
         Positioned.fill(
           child: Image.asset(
             'assets/images/backgrounds/FondoApp.png',
             fit: BoxFit.cover,
           ),
         ),
         // endregion banner background top

         // region Form
         Form(
             key: viewModel.formKey,
             child : Center(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.symmetric(horizontal: 40.0),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Image.asset(
                         'assets/images/logos/LogoGeo.png',
                         height: 120,
                       ),
                       Container(
                         padding: const EdgeInsets.all(20.0),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(20.0),
                           border: Border.all(
                             width: 2.0,
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withValues(alpha: 0.2),
                               blurRadius: 10,
                               offset: const Offset(0, 5),
                             ),
                           ],
                         ),
                         child: Column(
                           children: [
                             // region INPUT USER
                             TextFormField(
                               controller: viewModel.emailController,
                               decoration: InputDecoration(
                                 filled: true,
                                 fillColor: Colors.grey[100],
                                 hintText: 'USUARIO',
                                 prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(10.0),
                                   borderSide: BorderSide.none,
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                               ),
                               validator: (value) =>
                               (value == null || value.length < 4) ? 'Mínimo 6 caracteres' : null,
                             ),
                             // endregion INPUT USER
                             const SizedBox(height: 15),
                             // region INPUT PASSWORD
                             TextFormField(
                               controller: viewModel.passwordController,
                               obscureText: viewModel.obscurePassword,
                               autocorrect: false,
                               decoration: InputDecoration(
                                 hintText: '**********',
                                 filled: true,
                                 fillColor: Colors.grey.withOpacity(0.1),
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(8),
                                   borderSide: BorderSide(
                                     color: Colors.grey.withOpacity(0.3),
                                     width: 1,
                                   ),
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(8),
                                   borderSide: BorderSide(
                                     color: Colors.grey.withOpacity(0.3),
                                     width: 1,
                                   ),
                                 ),
                                 suffixIcon: IconButton(
                                   icon: Icon(
                                     viewModel.obscurePassword
                                         ? Icons.visibility_off
                                         : Icons.visibility,
                                     color: Colors.grey,
                                   ),
                                   onPressed: () {
                                     setState(() {
                                       viewModel.obscurePassword = !viewModel.obscurePassword;
                                     });
                                   },
                                 ),
                               ),
                               validator: (value) {
                                 if (value == null || value.length < 4) {
                                   return 'Mínimo 4 caracteres';
                                 }
                                 return null;
                               },
                             ),

                             const SizedBox(height: 20),

                             // Login Button
                             viewModel.isLoading
                                 ? const Center(child: CircularProgressIndicator())
                                 : ElevatedButton(
                               onPressed: () async {
                                 if (viewModel.formKey.currentState!.validate()) {
                                   final success = await viewModel.login(
                                     viewModel.emailController.text,
                                     viewModel.passwordController.text,
                                   );

                                   if (!mounted) return;

                                   if (success) {
                                     Navigator.pushReplacement(
                                       context,
                                       MaterialPageRoute(builder: (context) => const ListTicketView()),
                                     );
                                   } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Credenciales incorrectas')),
                                     );
                                   }
                                 }
                               },
                               child: const Text('Entrar'),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 40),

                       // Version Info
                       Column(
                         children: [
                           Image.asset(
                             'assets/images/logos/LogoGeoV.png',
                             height: 40,
                           ),
                           const SizedBox(height: 5),
                           const Text(
                             'Version 2.0',
                             style: TextStyle(
                               color: Colors.grey,
                               fontSize: 12,
                             ),
                           ),
                         ],
                       ),

                     ],
                   ),
                 )
             )
         )
         // endregion Form

       ],

      )

    );
  }
}
