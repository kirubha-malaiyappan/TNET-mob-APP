import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static Future<void> saveAuth(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<Map<String, dynamic>> getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final password = prefs.getString('password') ?? '';
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return {
      'email': email,
      'password': password,
      'isLoggedIn': isLoggedIn,
    };
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.setBool('isLoggedIn', false);
  }
}



// import 'package:shared_preferences/shared_preferences.dart';


// class AuthStorage {
//   static const String _tokenKey = 'auth_token';
//   static const String _emailKey = 'auth_email';
  
//   // Save authentication data
//   static Future<void> saveAuth(String email, String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_tokenKey, token);
//     await prefs.setString(_emailKey, email);
//   }
  
//   // Get authentication data
//   static Future<Map<String, String?>> getAuth() async {
//     final prefs = await SharedPreferences.getInstance();
//     return {
//       'email': prefs.getString(_emailKey),
//       'token': prefs.getString(_tokenKey),
//     };
//   }
  
//   // Clear authentication data (logout)
//   static Future<void> clearAuth() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_tokenKey);
//     await prefs.remove(_emailKey);
//   }
  
//   // Check if user is authenticated
//   static Future<bool> isAuthenticated() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString(_tokenKey);
//     return token != null && token.isNotEmpty;
//   }
// }