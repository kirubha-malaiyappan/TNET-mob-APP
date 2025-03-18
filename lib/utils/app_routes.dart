import 'package:flutter/material.dart';
import 'package:login_page/login_page.dart';

import '../line_page.dart';
import '../location_page.dart';


class AppRoutes {
  static const String login = '/login';
  static const String location = '/location';
  static const String lines = '/lines';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    
  };

  // Helper method to navigate to location page with email
  static void navigateToLocation(BuildContext context, String email) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => LocationPage(email: email),
      ),
    );
  }

  // Helper method to navigate to lines page
  static void navigateToLines(BuildContext context, String factoryName, String shopFloorName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinesPage(
          factoryName: factoryName,
          shopFloorName: shopFloorName,
        ),
      ),
    );
  }
}