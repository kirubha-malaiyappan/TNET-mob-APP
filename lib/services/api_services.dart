import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:login_page/res/constants.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  
  ApiResponse({this.data, this.error, this.success = false});
  
  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, success: true);
  }
  
  factory ApiResponse.error(String error) {
    return ApiResponse(error: error, success: false);
  }
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);
  
  // Login API call
  Future<ApiResponse<String>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseIpAddress}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);
      
      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return ApiResponse.success(responseBody['token'] ?? '');
      } else {
        return ApiResponse.error(responseBody['message'] ?? 'Authentication failed');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }
  
  // Get locations
  Future<ApiResponse<List<String>>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseIpAddress}/locations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return ApiResponse.success(List<String>.from(responseBody['locations']));
      } else {
        return ApiResponse.error(responseBody['message'] ?? 'Failed to load locations');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
      //print('Login error: $error');
    } catch (e) {
      return ApiResponse.error('Error loading locations: $e');
    }
  }
  
  // Get shop floors
  Future<ApiResponse<List<String>>> getShopFloors(String location) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseIpAddress}/shopfloors/$location'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return ApiResponse.success(List<String>.from(responseBody['shopFloors']));
      } else {
        return ApiResponse.error(responseBody['message'] ?? 'Failed to load shop floors');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
    } catch (e) {
      return ApiResponse.error('Error loading shop floors: $e');
    }
  }
  
  // Get lines for a shop floor
  Future<ApiResponse<List<String>>> getLines(String location, String shopFloor) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseIpAddress}/lines/$location/$shopFloor'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return ApiResponse.success(List<String>.from(responseBody['lines']));
      } else {
        return ApiResponse.error(responseBody['message'] ?? 'Failed to load lines');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
    } catch (e) {
      return ApiResponse.error('Error loading lines: $e');
    }
  }
  
  // Get production lines data
  Future<ApiResponse<Map<String, List<dynamic>>>> getProductionLines(String factoryName, String shopFloorName) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseIpAddress}/lines/$factoryName/$shopFloorName'),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data['status'] == 'success' && data['productionLines'] != null) {
          final Map<String, List<dynamic>> productionLines = 
              (data['productionLines'] as Map?)?.map((key, value) => 
                MapEntry(key.toString(), List<dynamic>.from(value ?? []))) ?? {};
          
          return ApiResponse.success(productionLines);
        } else {
          return ApiResponse.error(data?['message'] ?? 'No data available');
        }
      } else {
        return ApiResponse.error('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // Get Overall Plant OEE data
  Future<ApiResponse<Map<String, List<dynamic>>>> getOverallPlantOEE(String factoryName, String shopFloorName, String fromTime, String toTime) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseIpAddress}/overallPlantOEE/$factoryName/$shopFloorName?fromTime=$fromTime&toTime=$toTime'),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data['status'] == 'success' && data['plantMetrics'] != null) {
          final Map<String, List<dynamic>> overallPlantOEEprod = 
              (data['plantMetrics'] as Map?)?.map((key, value) => 
                MapEntry(key.toString(), List<dynamic>.from(value ?? []))) ?? {};
          
          return ApiResponse.success(overallPlantOEEprod);
        } else {
          return ApiResponse.error(data?['message'] ?? 'No data available');
        }
      } else {
        return ApiResponse.error('Failed to fetch getOverallPlantOEE data. Status code: ${response.statusCode}');
      }
    } on TimeoutException {
      return ApiResponse.error('Connection timed out');
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }
}

 
