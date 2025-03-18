import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_page/login_page.dart';
import 'package:login_page/location_page.dart';
import 'package:login_page/providers/auth_provider.dart';
import 'package:login_page/providers/location_provider.dart';
import 'package:login_page/providers/line_provider.dart';
import 'package:login_page/providers/machine_metrics_provider.dart';
import 'package:login_page/utils/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get the login flag and stored email from SharedPreferences.
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final email = prefs.getString('email') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => LineProvider()),
        ChangeNotifierProvider(create: (_) => MachineMetricsProvider()),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
        email: email,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String email;
  const MyApp({Key? key, required this.isLoggedIn, required this.email}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize AuthProvider to sync with stored auth data.
    Provider.of<AuthProvider>(context, listen: false).initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Factory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Archivo',
      ),
      // If user is already logged in, start with LocationPage (passing the stored email)
      // otherwise, start with the LoginPage.
      home: widget.isLoggedIn
          ? LocationPage(email: widget.email)
          : const LoginPage(),
      // Optionally keep your routes map if you use named navigation elsewhere.
      routes: AppRoutes.routes,
    );
  }
}