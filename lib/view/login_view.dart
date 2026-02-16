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
      body: Stack(
       children: [
         // region banner background top
         Positioned.fill(
           child: Image.asset(
             'assets/images/backgrounds/FondoApp3.png',
             fit: BoxFit.cover,
           ),
         ),
         // endregion banner background top

         // region Form
         Form(
             key: viewModel.formKey,
             child : Center(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const SizedBox(height: 180), // Push form down
                       Container(
                         padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.92), // Glass effect
                           borderRadius: BorderRadius.circular(30.0),
                           border: Border.all(color: Colors.white, width: 2.0),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 25,
                               offset: const Offset(0, 15),
                             ),
                           ],
                         ),
                         child: Column(
                           children: [
                             Text(
                               'Iniciar Sesión',
                               style: TextStyle(
                                 fontSize: 28,
                                 fontWeight: FontWeight.w800,
                                 color: Theme.of(context).primaryColor, // Use primary color
                                 letterSpacing: 1.2,
                               ),
                             ),
                             const SizedBox(height: 40),
                             // region INPUT USER
                             TextFormField(
                               controller: viewModel.emailController,
                               decoration: InputDecoration(
                                 filled: true,
                                 fillColor: Colors.white,
                                 hintText: 'Usuario',
                                 prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide.none,
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                 ),
                                 focusedBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
                               ),
                               validator: (value) =>
                               (value == null || value.length < 4) ? 'Mínimo 6 caracteres' : null,
                             ),
                             // endregion INPUT USER
                             const SizedBox(height: 20),
                             // region INPUT PASSWORD
                             TextFormField(
                               controller: viewModel.passwordController,
                               obscureText: viewModel.obscurePassword,
                               autocorrect: false,
                               decoration: InputDecoration(
                                 hintText: 'Contraseña',
                                 filled: true,
                                 fillColor: Colors.white,
                                 prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide.none,
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                 ),
                                 focusedBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(15.0),
                                   borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
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

                             const SizedBox(height: 30),

                             // Login Button
                             viewModel.isLoading
                                 ? const Center(child: CircularProgressIndicator())
                                 : SizedBox(
                                     width: double.infinity,
                                     child: ElevatedButton(
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
                                       style: ElevatedButton.styleFrom(
                                         padding: const EdgeInsets.symmetric(vertical: 18),
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(15),
                                         ),
                                         elevation: 5,
                                         backgroundColor: Theme.of(context).primaryColor,
                                         foregroundColor: Colors.white,
                                       ),
                                       child: const Text(
                                         'ENTRAR',
                                         style: TextStyle(
                                           fontSize: 16,
                                           fontWeight: FontWeight.bold,
                                           letterSpacing: 1.5,
                                         ),
                                       ),
                                     ),
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
