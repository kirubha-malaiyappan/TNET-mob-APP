import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:login_page/res/constants.dart';
import '../services/api_services.dart';


class Overallplantdata {
  final DateTime fromTIME;
  final DateTime toTIME;
  final String machinename;
  final double productivity;
  final double quality;
  final double utilization;
  final double oee;
  final int energyconsumption;
  final int goodParts;
  final int rejectParts;

  Overallplantdata({
    required this.fromTIME,
    required this.toTIME,
    required this.machinename,
    required this.productivity,
    required this.quality,
    required this.utilization,
    required this.oee,
    required this.energyconsumption,
    required this.goodParts,
    required this.rejectParts,
  });

  factory Overallplantdata.fromJson(Map<String, dynamic> json) {

     int parseInt(dynamic value) {
    if (value == null) return 0; // Default if null
    if (value is int) return value; // Return directly if int
    return int.tryParse(value.toString()) ?? 0; // Convert string to int
  }
    // ✅ Utility function to parse DateTime safely
  
     String parseString(dynamic value) {
      if (value == null) return ''; // Default empty string
      return value.toString(); // Convert to string
    }
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
     DateTime parseDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return DateTime.now(); // Return current time if null
    }
    try {
      return DateTime.parse(value.toString()).toLocal(); // Convert to local time
    } catch (e) {
      print('Error parsing date: $value');
      return DateTime.now();
    }
  }

    return Overallplantdata(
    fromTIME: parseDateTime(json['from_time']),
    toTIME: parseDateTime(json['to_time']),
    machinename: parseString(json['machine_name']),
    productivity: parseDouble(json['productivity_percentage']),
    quality: parseDouble(json['quality_percentage']),
    utilization: parseDouble(json['utilization_percentage']),
    oee: parseDouble(json['overall_equipment_effectiveness_percentage']),
    energyconsumption: parseInt(json['energy_consumption']),
    goodParts: parseInt(json['good_parts_count']),
    rejectParts: parseInt(json['reject_parts_count']),
    
  );
  } 
}

class OverallAVGplantdata {
  final double avgproductivity;
  final double avgquality;
  final double avgutilization;
  final double avgoee;

  OverallAVGplantdata({
    required this.avgproductivity,
    required this.avgquality,
    required this.avgutilization,
    required this.avgoee,
  });

  factory OverallAVGplantdata.fromJson(Map<String, dynamic> json) {

     
    // ✅ Utility function to parse DateTime safely
  
     
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OverallAVGplantdata(
    avgutilization: parseDouble((json['avg_utilization'] as num?)?.toDouble() ?? 0.0,),
    avgproductivity: parseDouble((json['avg_productivity'] as num?)?.toDouble() ?? 0.0,),
    avgquality: parseDouble((json['avg_quality'] as num?)?.toDouble() ?? 0.0),
    avgoee: parseDouble( (json['avg_oee'] as num?)?.toDouble() ?? 0.0),
    
  );
  } 
}

class ProductionLine {
  final String id;
  final List<dynamic> machines;

  ProductionLine({required this.id, required this.machines});
}

class LineProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, List<dynamic>> _productionLines = {};
  List<Overallplantdata> _overallplantoee = [];
   List<OverallAVGplantdata> _avgplantoee = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  String _error = '';

  // Getters
  Map<String, List<dynamic>> get productionLines => _productionLines;
  List<Overallplantdata> get overallPlantOEE => _overallplantoee;
  List<OverallAVGplantdata> get avgPlantOee => _avgplantoee;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialize data fetching with auto-refresh
  void initializeAndFetch(String factoryName, String shopFloorName) {
    fetchProductionLines(factoryName, shopFloorName);
    fetchOverallPlantOEE(factoryName, shopFloorName);
    fetchAVGPlantOEE(factoryName, shopFloorName);
    
    // Set up auto-refresh timer
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchProductionLines(factoryName, shopFloorName);
      // fetchoverallPlantOEE(factoryName, shopFloorName);
    });
  }

  // Cleanup
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Fetch production lines data
  Future<void> fetchProductionLines(String factoryName, String shopFloorName) async {
    if (_productionLines.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.getProductionLines(factoryName, shopFloorName);
      
      if (response.success && response.data != null) {
        _productionLines = response.data!;
        _isLoading = false;
        print(response.data);
      } else {
        _handleError(response.error ?? 'Failed to fetch data');
      }
    } catch (e) {
      _handleError('Error: ${e.toString()}');
    }
    
    notifyListeners();
  }



Future<void> fetchOverallPlantOEE(String factoryName, String shopFloorName) async {
   if (_overallplantoee.isEmpty) {
    _isLoading = true;
  }
  _errorMessage = '';
  notifyListeners();
 
  try {
    DateTime now = DateTime.now();
    DateTime roundedCurrentHour = DateTime(now.year, now.month, now.day, now.hour, 0, 0);

    // Get the previous hour range
    DateTime fromTime = roundedCurrentHour.subtract(Duration(hours: 1));
    DateTime toTime = roundedCurrentHour;

    // Format as 'yyyy-MM-dd HH:mm:ss' for API compatibility
    String formattedFromTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(fromTime);
    String formattedToTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(toTime);

    print('Fetching OEE for time range: $formattedFromTime to $formattedToTime');

    final uri = Uri.parse('${Constants.baseIpAddress}/overallPlantOEE/$factoryName/$shopFloorName')
        .replace(queryParameters: {
      'fromTime': formattedFromTime,
      'toTime': formattedToTime,
    });

    print('Request URL overallplantoee: $uri');

    final response = await http.get(uri);

    print('Response status code overallplantoee: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['debug'] != null) {
        print('${data['plantMetrics']}');
        print('Debug info from server mold: ${data['debug']}');
      }

      final List<dynamic> metricsData = (data['plantMetrics'] as List?) ?? [];

      if (metricsData.isEmpty) {
        _overallplantoee = [];
        _error = 'No data found for the selected time period';
        notifyListeners();
        return;
      }

      _overallplantoee = metricsData.map((item) => Overallplantdata.fromJson(item)).toList();
        

      print('Loaded ${_overallplantoee.length} metrics');
      if (_overallplantoee.isNotEmpty) {
        print('Time range in response: '
            '$formattedToTime to $formattedToTime');
      }

      _error = '';
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown error');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  } catch (e, stackTrace) {
    print('Error fetching metrics: $e');
    print('Stack trace: $stackTrace');
    _error = 'Error loading metrics: $e';
  } finally {
    _isLoading = false;
    notifyListeners();

  }
}

 Future<void> fetchAVGPlantOEE(String factoryName, String shopFloorName) async {
   if (_avgplantoee.isEmpty) {
    _isLoading = true;
  }
  _errorMessage = '';
  notifyListeners();
 
  try {
    DateTime now = DateTime.now();
    DateTime roundedCurrentHour = DateTime(now.year, now.month, now.day, now.hour, 0, 0);

    // Get the previous hour range
    DateTime fromTime = roundedCurrentHour.subtract(Duration(hours: 1));
    DateTime toTime = roundedCurrentHour;

    // Format as 'yyyy-MM-dd HH:mm:ss' for API compatibility
    String formattedFromTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(fromTime);
    String formattedToTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(toTime);

    print('Fetching OEE for time range: $formattedFromTime to $formattedToTime');

    final uri = Uri.parse('${Constants.baseIpAddress}/avgPlantOEE/$factoryName/$shopFloorName')
        .replace(queryParameters: {
      'fromTime': formattedFromTime,
      'toTime': formattedToTime,
    });

    print('Request URL overallplantoee: $uri');

    final response = await http.get(uri);

    print('Response status code overallplantoee: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['debug'] != null) {
        print('${data['plantMetrics']}');
        print('Debug info from server mold: ${data['debug']}');
      }

      final List<dynamic> metricsData = (data['avgplantMetrics'] as List?) ?? [];

      if (metricsData.isEmpty) {
        _avgplantoee = [];
        _error = 'No data found for the selected time period';
        notifyListeners();
        return;
      }

      _avgplantoee = metricsData.map((item) => OverallAVGplantdata.fromJson(item)).toList();
        

      print('Loaded ${_avgplantoee.length} metrics');
      if (_avgplantoee.isNotEmpty) {
        print('Time range in response: '
            '$formattedToTime to $formattedToTime');
      }

      _error = '';
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown error');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  } catch (e, stackTrace) {
    print('Error fetching metrics: $e');
    print('Stack trace: $stackTrace');
    _error = 'Error loading metrics: $e';
  } finally {
    _isLoading = false;
    notifyListeners();

  }
}
 
  void _handleError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _productionLines = {};
    _overallplantoee = [];
    _avgplantoee = [];
  }

  // Helper methods for UI
  Color getColorFromCode(String colorCode) {
    switch (colorCode) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      case 'grey': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String colorCode) {
    switch (colorCode) {
      case 'green': return Icons.play_circle_filled;
      case 'yellow': return Icons.play_circle_filled;
      case 'red': return Icons.stop_circle;
      case 'grey': return Icons.error_outline;
      default: return Icons.help_outline;
    }
  }
}
