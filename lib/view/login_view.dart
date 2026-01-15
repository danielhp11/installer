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
  // final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();

  // @override
  // void dispose() {
  //   _emailController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);

    // @override
    // void initState() {
    //   super.initState();
    //
    //   viewModel.emailController.text = "master@geovoy.com";
    //   viewModel.passwordController.text = "admin";
    // }

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

                             // endregion INPUT PASSWORD

                             // Keep Session Checkbox
                             // Row(
                             //   children: [
                             //     Checkbox(
                             //       value: _keepSession,
                             //       activeColor: AppColors.buttonNavy,
                             //       onChanged: (value) {
                             //         setState(() {
                             //           _keepSession = value ?? false;
                             //         });
                             //       },
                             //     ),
                             //     const Expanded(
                             //       child: Text(
                             //         'Mantener sesión iniciada',
                             //         style: TextStyle(
                             //           color: Colors.black87,
                             //           fontWeight: FontWeight.w600,
                             //         ),
                             //       ),
                             //     ),
                             //   ],
                             // ),
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
                             // Consumer<LoginViewModel>(
                             //   builder: (context, viewModel, child) {
                             //     return Column(
                             //       children: [
                             //         // Error message display
                             //         if (viewModel.errorMessage != null)
                             //           Container(
                             //             padding: const EdgeInsets.all(12),
                             //             margin: const EdgeInsets.only(bottom: 12),
                             //             decoration: BoxDecoration(
                             //               color: Colors.red.shade50,
                             //               borderRadius: BorderRadius.circular(8),
                             //               border: Border.all(color: Colors.red.shade300),
                             //             ),
                             //             child: Row(
                             //               children: [
                             //                 Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                             //                 const SizedBox(width: 8),
                             //                 Expanded(
                             //                   child: Text(
                             //                     viewModel.errorMessage!,
                             //                     style: TextStyle(
                             //                       color: Colors.red.shade700,
                             //                       fontSize: 14,
                             //                     ),
                             //                   ),
                             //                 ),
                             //               ],
                             //             ),
                             //           ),
                             //         SizedBox(
                             //           width: double.infinity,
                             //           height: 50,
                             //           child: ElevatedButton(
                             //             onPressed: viewModel.isLoading
                             //                 ? null
                             //                 : () {
                             //               // Clear previous error
                             //               // viewModel.clearError();
                             //               // _showCompanySelectionModal(context);
                             //             },
                             //             style: ElevatedButton.styleFrom(
                             //               shape: RoundedRectangleBorder(
                             //                 borderRadius: BorderRadius.circular(10.0),
                             //               ),
                             //               elevation: 2,
                             //             ),
                             //             child: viewModel.isLoading
                             //                 ? const SizedBox(
                             //               height: 20,
                             //               width: 20,
                             //               child: CircularProgressIndicator(
                             //                 color: Colors.white,
                             //                 strokeWidth: 2,
                             //               ),
                             //             )
                             //                 : const Text(
                             //               'INGRESAR',
                             //               style: TextStyle(
                             //                 color: Colors.white,
                             //                 fontSize: 16,
                             //                 fontWeight: FontWeight.bold,
                             //               ),
                             //             ),
                             //           ),
                             //         ),
                             //       ],
                             //     );
                             //   },
                             // ),
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
      // Padding(
      //   padding: const EdgeInsets.all(24.0),
      //   child: Form(
      //     key: viewModel.formKey,
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       crossAxisAlignment: CrossAxisAlignment.stretch,
      //       children: [
      //         TextFormField(
      //           controller: viewModel.emailController,
      //           decoration: const InputDecoration(
      //             labelText: 'Correo Electrónico',
      //             prefixIcon: Icon(Icons.email),
      //           ),
      //           keyboardType: TextInputType.emailAddress,
      //           validator: (value) =>
      //               (value == null || !value.contains('@')) ? 'Email inválido' : null,
      //         ),
      //         const SizedBox(height: 16),
      //         TextFormField(
      //           controller: viewModel.passwordController,
      //           decoration: const InputDecoration(
      //             labelText: 'Contraseña',
      //             prefixIcon: Icon(Icons.lock),
      //           ),
      //           obscureText: true,
      //           validator: (value) =>
      //               (value == null || value.length < 4) ? 'Mínimo 4 caracteres' : null,
      //         ),
      //         const SizedBox(height: 24),
      //         viewModel.isLoading
      //             ? const Center(child: CircularProgressIndicator())
      //             : ElevatedButton(
      //                 onPressed: () async {
      //                   if (viewModel.formKey.currentState!.validate()) {
      //                     final success = await viewModel.login(
      //                       viewModel.emailController.text,
      //                       viewModel.passwordController.text,
      //                     );
      //
      //                     if (!mounted) return;
      //
      //                     if (success) {
      //                       Navigator.pushReplacement(
      //                         context,
      //                         MaterialPageRoute(builder: (context) => const ListTicketView()),
      //                       );
      //                     } else {
      //                       ScaffoldMessenger.of(context).showSnackBar(
      //                         const SnackBar(content: Text('Credenciales incorrectas')),
      //                       );
      //                     }
      //                   }
      //                 },
      //                 child: const Text('Entrar'),
      //               ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}
