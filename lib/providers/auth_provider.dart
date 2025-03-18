import 'package:flutter/material.dart';
import '../res/auth_storage.dart';
import '../services/api_services.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  String _email = '';
  bool _isPasswordVisible = false;
  bool _isLoggedIn = false;

  // Getters
  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get email => _email;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isLoggedIn => _isLoggedIn;

  // Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Login method (stores email, password and isLoggedIn flag)
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    final response = await _apiService.login(email, password);
    
    if (response.success) {
      _status = AuthStatus.authenticated;
      _email = email;
      _isLoggedIn = true;
      
      // Save email, password, and login flag to SharedPreferences
      await AuthStorage.saveAuth(email, password);
      
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = response.error ?? 'Authentication failed';
      notifyListeners();
      return false;
    }
  }

  // Logout method clears the stored credentials and resets the login flag
  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _email = '';
    _isLoggedIn = false;
    await AuthStorage.clearAuth();
    notifyListeners();
  }

  // Reset error state
  void resetError() {
    _errorMessage = '';
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Initialize using stored SharedPreferences data
  Future<void> initialize() async {
    final authData = await AuthStorage.getAuth();
    if (authData['isLoggedIn'] == true) {
      _email = authData['email'] ?? '';
      _status = AuthStatus.authenticated;
      _isLoggedIn = true;
      notifyListeners();
    }
  }
}

// import 'package:flutter/material.dart';
// import '../res/auth_storage.dart';
// import '../services/api_services.dart';

// enum AuthStatus {
//   initial,
//   authenticating,
//   authenticated,
//   unauthenticated,
//   error
// }

// class AuthProvider extends ChangeNotifier {
//   final ApiService _apiService = ApiService();
  
//   AuthStatus _status = AuthStatus.initial;
//   String _errorMessage = '';
//   String _email = '';
//   bool _isPasswordVisible = false;
//   bool _isLoggedIn = false;

//   // Getters
//   AuthStatus get status => _status;
//   String get errorMessage => _errorMessage;
//   String get email => _email;
//   bool get isPasswordVisible => _isPasswordVisible;
//   bool get isAuthenticated => _status == AuthStatus.authenticated;
//   bool get isAuthenticating => _status == AuthStatus.authenticating;
//   bool get isLoggedIn =>  _isLoggedIn;

//   // Toggle password visibility
//   void togglePasswordVisibility() {
//     _isPasswordVisible = !_isPasswordVisible;
//     notifyListeners();
//   }

//   // Login method (now storing email and password only)
//   Future<bool> login(String email, String password) async {
//     _status = AuthStatus.authenticating;
//     _errorMessage = '';
//     notifyListeners();

//     final response = await _apiService.login(email, password);
    
//     if (response.success) {
//       _status = AuthStatus.authenticated;
//       _email = email;
//       _isLoggedIn = true;
//       // Save email and password to SharedPreferences and mark user as logged in
//       await AuthStorage.saveAuth(email, password);
      
//       notifyListeners();
//       return true;
//     } else {
//       _status = AuthStatus.error;
//       _errorMessage = response.error ?? 'Authentication failed';
//       notifyListeners();
//       return false;
//     }
//   }

//   // Logout method
//   Future<void> logout() async {
//     _status = AuthStatus.unauthenticated;
//     _email = '';
//     _isLoggedIn = false;
//     await AuthStorage.clearAuth();
//     notifyListeners();
//   }

//   // Reset error state
//   void resetError() {
//     _errorMessage = '';
//     if (_status == AuthStatus.error) {
//       _status = AuthStatus.unauthenticated;
//     }
//     notifyListeners();
//   }

//   // Initialize using stored SharedPreferences data
//   Future<void> initialize() async {
//     final authData = await AuthStorage.getAuth();
//     if (authData['isLoggedIn'] == true) {
//       _email = authData['email'] ?? '';
//       _status = AuthStatus.authenticated;
//       notifyListeners();
//     }
//   }
// }

// import 'package:flutter/material.dart';
// import '../res/auth_storage.dart';
// import '../services/api_services.dart';

// enum AuthStatus {
//   initial,
//   authenticating,
//   authenticated,
//   unauthenticated,
//   error
// }

// class AuthProvider extends ChangeNotifier {
//   final ApiService _apiService = ApiService();
  
//   AuthStatus _status = AuthStatus.initial;
//   String _errorMessage = '';
//   String _email = '';
//   String _token = '';
//   bool _isPasswordVisible = false;

//   // Getters
//   AuthStatus get status => _status;
//   String get errorMessage => _errorMessage;
//   String get email => _email;
//   String get token => _token;
//   bool get isPasswordVisible => _isPasswordVisible;
//   bool get isAuthenticated => _status == AuthStatus.authenticated;
//   bool get isAuthenticating => _status == AuthStatus.authenticating;

//   // Toggle password visibility
//   void togglePasswordVisibility() {
//     _isPasswordVisible = !_isPasswordVisible;
//     notifyListeners();
//   }

//   // Login method
//   Future<bool> login(String email, String password) async {
//     _status = AuthStatus.authenticating;
//     _errorMessage = '';
//     notifyListeners();

//     final response = await _apiService.login(email, password);
    
//     if (response.success) {
//     _status = AuthStatus.authenticated;
//     _email = email;
//     _token = response.data ?? '';
    
//     // Save auth data
//     await AuthStorage.saveAuth(email, _token);
    
//     notifyListeners();
//     return true;
//   }
//    else {
//       _status = AuthStatus.error;
//       _errorMessage = response.error ?? 'Authentication failed';
//       notifyListeners();
//       return false;
//     }
//   }

//   // Logout method
//  Future<void> logout() async {
//   _status = AuthStatus.unauthenticated;
//   _email = '';
//   _token = '';
//   await AuthStorage.clearAuth();
  
//   notifyListeners();
// }


//   // Reset error state
//   void resetError() {
//     _errorMessage = '';
//     if (_status == AuthStatus.error) {
//       _status = AuthStatus.unauthenticated;
//     }
//     notifyListeners();
//   }
//   Future<void> initialize() async {
//   final authData = await AuthStorage.getAuth();
//   if (authData['token'] != null && authData['token']!.isNotEmpty) {
//     _token = authData['token']!;
//     _email = authData['email'] ?? '';
//     _status = AuthStatus.authenticated;
//     notifyListeners();
//   }
// }
// }