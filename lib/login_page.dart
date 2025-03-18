import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:login_page/location_page.dart';
import 'package:login_page/res/styles/app_styles.dart';
import 'package:login_page/res/styles/media.dart';
import 'package:login_page/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset any error state when the login page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).resetError();
      
    });
  }

 

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
    
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPage(
            email: emailController.text.trim(),
          ),
        ),
      );
    } else if (mounted && authProvider.errorMessage.isNotEmpty) {
      showErrorDialog(authProvider.errorMessage);
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppStyles.basecolor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    height: size.height * 0.15,
                    width: size.width * 0.3,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppMedia.logo),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Main Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppStyles.basecolor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppStyles.basefontfam,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 24),
                        // Email Field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            labelStyle: TextStyle(color: AppStyles.textColor2),
                            filled: true,
                            fillColor: AppStyles.smallboxColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: emailController.text.isNotEmpty
                                ? Icon(Icons.check, color: AppStyles.secondBaseColor)
                                : null,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: !authProvider.isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: AppStyles.textColor2),
                            filled: true,
                            fillColor: AppStyles.smallboxColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                authProvider.isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppStyles.textColor2,
                              ),
                              onPressed: () {
                                authProvider.togglePasswordVisibility();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                        authProvider.isAuthenticating
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppStyles.secondBaseColor,
                                    foregroundColor: AppStyles.basecolor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppStyles.basefontfam,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:login_page/location_page.dart';
// import 'package:login_page/res/styles/app_styles.dart';
// import 'package:login_page/res/styles/media.dart';
// import 'package:login_page/providers/auth_provider.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // Reset any error state when the login page is loaded
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<AuthProvider>(context, listen: false).resetError();
//     });
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   void _handleLogin() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
//     final success = await authProvider.login(
//       emailController.text.trim(),
//       passwordController.text.trim(),
//     );
    
//     if (success && mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => LocationPage(
//             email: emailController.text.trim(),
//           ),
//         ),
//       );
//     } else if (mounted && authProvider.errorMessage.isNotEmpty) {
//       showErrorDialog(authProvider.errorMessage);
//     }
//   }

//   void showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final authProvider = Provider.of<AuthProvider>(context);
    
//     return Scaffold(
//       backgroundColor: AppStyles.basecolor,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo
//                   Container(
//                     height: size.height * 0.15,
//                     width: size.width * 0.3,
//                     decoration: const BoxDecoration(
//                       image: DecorationImage(
//                         image: AssetImage(AppMedia.logo),
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   // Main Container
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: AppStyles.basecolor,
//                       borderRadius: BorderRadius.circular(32),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Welcome',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: AppStyles.basefontfam,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         const SizedBox(height: 24),
//                         // Email Field
//                         TextField(
//                           controller: emailController,
//                           decoration: InputDecoration(
//                             labelText: 'E-mail',
//                             labelStyle: TextStyle(color: AppStyles.textColor2),
//                             filled: true,
//                             fillColor: AppStyles.smallboxColor,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: emailController.text.isNotEmpty
//                                 ? Icon(Icons.check, color: AppStyles.secondBaseColor)
//                                 : null,
//                           ),
//                           keyboardType: TextInputType.emailAddress,
//                         ),
//                         const SizedBox(height: 16),
//                         // Password Field
//                         TextField(
//                           controller: passwordController,
//                           obscureText: !authProvider.isPasswordVisible,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             labelStyle: TextStyle(color: AppStyles.textColor2),
//                             filled: true,
//                             fillColor: AppStyles.smallboxColor,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 authProvider.isPasswordVisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: AppStyles.textColor2,
//                               ),
//                               onPressed: () {
//                                 authProvider.togglePasswordVisibility();
//                               },
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         // Login Button
//                         authProvider.isAuthenticating
//                             ? const Center(child: CircularProgressIndicator())
//                             : SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   onPressed: _handleLogin,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppStyles.secondBaseColor,
//                                     foregroundColor: AppStyles.basecolor,
//                                     padding: const EdgeInsets.symmetric(vertical: 16),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     'Login',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       fontFamily: AppStyles.basefontfam,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }