// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:login_page/res/constants.dart';

// class Overallplantdata {
//   final DateTime timestamp;
//   final String moldid;
//   final int goodparts;
//   final int rejectparts;
//   final int totalparts;
//   final int materiallconsumption;
//   final int energyconsumption;

//   Overallplantdata({
//     required this.timestamp,
//     required this.moldid,
//     required this.goodparts,
//     required this.rejectparts,
//     required this.totalparts,
//     required this.materiallconsumption,
//     required this.energyconsumption,
//   });

//   factory Overallplantdata.fromJson(Map<String, dynamic> json) {

//      int parseInt(dynamic value) {
//     if (value == null) return 0; // Default if null
//     if (value is int) return value; // Return directly if int
//     return int.tryParse(value.toString()) ?? 0; // Convert string to int
//   }
//     // ✅ Utility function to parse DateTime safely
//   DateTime parseDateTime(dynamic value) {
//     if (value == null || value.toString().isEmpty) {
//       return DateTime.now(); // Return current time if null
//     }
//     try {
//       return DateTime.parse(value.toString()).toLocal(); // Convert to local time
//     } catch (e) {
//       print('Error parsing date: $value');
//       return DateTime.now();
//     }
//   }
//      String parseString(dynamic value) {
//       if (value == null) return ''; // Default empty string
//       return value.toString(); // Convert to string
//     }

//     return Overallplantdata(
//     timestamp: parseDateTime(json['from_time']),
//     moldid: parseString(json['mold_id']),
//     goodparts: parseInt(json['good_parts_difference']),
//     rejectparts: parseInt(json['rejected_parts_difference']),
//     totalparts: parseInt(json['total_parts']),
//     materiallconsumption: parseInt(json['material_consumption']),
//     energyconsumption: parseInt(json['energy_consumption']),
//   );
//   } 
// }


// class overallPlantOEEProvider extends ChangeNotifier {
//   List<Overallplantdata> _metricsmold = [];
//   bool _isLoading = false;
//   String _error = '';
//   String selectedRange = '1H';
//   DateTime _fromDate = DateTime.now().subtract(const Duration(hours: 1));
//   DateTime _toDate = DateTime.now();
  
//   // Getters
//   List<Overallplantdata> get metricsmold => _metricsmold;
//   bool get isLoading => _isLoading;
//   String get error => _error;
//   DateTime get fromDate => _fromDate;
//   DateTime get toDate => _toDate;
  
//   /

 



//   Future<void> fetchmoldMetrics({String? ipAddress}) async {
//   if ((ipAddress?.isEmpty ?? true) && _currentIpAddress.isEmpty) {
//     _error = 'No IP address specified';
//     notifyListeners();
//     return;
//   }

//   final String targetIp = ipAddress ?? _currentIpAddress;
//   _currentIpAddress = targetIp; // Store for future refreshes

//   _isLoading = true;
//   _error = '';
//   notifyListeners();

//   try {
 


//     final uri = Uri.parse('${Constants.baseIpAddress}/machine-metrics-moldwise/$targetIp')
//         .replace(queryParameters: {
//       'fromTime': fromTimeStr,
//       'toTime': toTimeStr,
//     });

//     print('Request URL mold: $uri');

//     final response = await http.get(uri);

//     print('Response status code mold: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['debug'] != null) {
//         print('Debug info from server mold: ${data['debug']}');
//       }

//       final List<dynamic> metricsData = (data['metrics'] as List?) ?? [];

//       if (metricsData.isEmpty) {
//         _metricsmold = [];
//         _error = 'No data found for the selected time period';
//         notifyListeners();
//         return;
//       }

//       _metricsmold = metricsData.map((item) => Overallplantdata.fromJson(item)).toList()
//         ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

//       print('Loaded ${_metricsmold.length} metrics');
//       if (_metricsmold.isNotEmpty) {
//         print('Time range in response: '
//             '${_metricsmold.first.timestamp} to ${_metricsmold.last.timestamp}');
//       }

//       _error = '';
//     } else {
//       try {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['message'] ?? 'Unknown error');
//       } catch (_) {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     }
//   } catch (e, stackTrace) {
//     print('Error fetching metrics: $e');
//     print('Stack trace: $stackTrace');
//     _error = 'Error loading metrics: $e';
//   } finally {
//     _isLoading = false;
//     notifyListeners();

//   }
// }

  
//   // Store the current IP address for refreshes
//   String _currentIpAddress = '';
// }