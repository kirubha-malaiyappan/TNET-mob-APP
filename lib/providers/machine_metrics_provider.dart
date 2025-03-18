import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:login_page/res/constants.dart';


class MetricsData {
  final DateTime timestamp;
  final double avgProductivity;
  final double avgQuality;
  final double avgUtilization;
  final double avgOEE;

  MetricsData({
    required this.timestamp,
    required this.avgProductivity,
    required this.avgQuality,
    required this.avgUtilization,
    required this.avgOEE,
  });

  factory MetricsData.fromJson(Map<String, dynamic> json) {
    // ✅ Utility function to parse DateTime safely
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

    // Handle potential null or string values for numeric fields
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MetricsData(
      timestamp: parseDateTime(json['from_time']),
      avgProductivity: parseDouble(json['AvgProductivity']),
      avgQuality: parseDouble(json['QualityPercentage']),
      avgUtilization: parseDouble(json['AvgUtilization']),
      avgOEE: parseDouble(json['OEE_percentage']),
    );
  }
  
}


class MetricsDataTAble {
  final DateTime timestamp;
  final DateTime fromtime;
  final DateTime totime;
  final double productivity;
  final double quality;
  final double utilization;
  final double oee;

  MetricsDataTAble({
    required this.timestamp,
    required this.fromtime,
    required this.totime,
    required this.productivity,
    required this.quality,
    required this.utilization,
    required this.oee,
  });

  factory MetricsDataTAble.fromJson(Map<String, dynamic> json) {
    // ✅ Utility function to parse DateTime safely
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

    // Handle potential null or string values for numeric fields
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MetricsDataTAble(
      timestamp: parseDateTime(json['from_time']),
      fromtime: parseDateTime(json['from_time']),
      totime: parseDateTime(json['to_time']),
      productivity: parseDouble(json['productivity_percentage']),
      quality: parseDouble(json['quality_percentage']),
      utilization: parseDouble(json['utilization_percentage']),
      oee: parseDouble(json['overall_equipment_effectiveness_percentage']),
    );
  }
  
  String formattedFromTime() => DateFormat('dd/MM/yy HH:mm').format(fromtime);
  String formattedToTime() => DateFormat('dd/MM/yy HH:mm').format(totime);
}



class MetricsmoldData {
  final DateTime timestamp;
  final String moldid;
  final int goodparts;
  final int rejectparts;
  final int totalparts;
  final int materiallconsumption;
  final int energyconsumption;

  MetricsmoldData({
    required this.timestamp,
    required this.moldid,
    required this.goodparts,
    required this.rejectparts,
    required this.totalparts,
    required this.materiallconsumption,
    required this.energyconsumption,
  });

  factory MetricsmoldData.fromJson(Map<String, dynamic> json) {

     int parseInt(dynamic value) {
    if (value == null) return 0; // Default if null
    if (value is int) return value; // Return directly if int
    return int.tryParse(value.toString()) ?? 0; // Convert string to int
  }
    // ✅ Utility function to parse DateTime safely
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
     String parseString(dynamic value) {
      if (value == null) return ''; // Default empty string
      return value.toString(); // Convert to string
    }

    return MetricsmoldData(
    timestamp: parseDateTime(json['from_time']),
    moldid: parseString(json['mold_id']),
    goodparts: parseInt(json['good_parts_difference']),
    rejectparts: parseInt(json['rejected_parts_difference']),
    totalparts: parseInt(json['total_parts']),
    materiallconsumption: parseInt(json['material_consumption']),
    energyconsumption: parseInt(json['energy_consumption']),
  );
  } 
}


class MachineMetricsProvider extends ChangeNotifier {
  List<MetricsData> _metrics = [];
  List<MetricsmoldData> _metricsmold = [];
   List<MetricsDataTAble> _metricstable = [];
  bool _isLoading = false;
  String _error = '';
  String selectedRange = '1H';
  DateTime _fromDate = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _toDate = DateTime.now();
  
  // Getters
  List<MetricsData> get metricsdata => _metrics;
  List<MetricsmoldData> get metricsmold => _metricsmold;
  List<MetricsDataTAble> get metricstable => _metricstable;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  
  // Date format
  final DateFormat formatter = DateFormat('dd/MM/yy HH:mm');

  // Set date range
  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }
  
  // Apply predefined time range
  void applyTimeRange(String range, duration) {
    // setState(() {
       selectedRange = range;
    // });
    //_toDate = _fromDate.add(duration);
    _fromDate = _toDate.add(duration);
    notifyListeners();
    fetchMetrics();
    fetchMetricstable(); // Automatically fetch new data
    fetchmoldMetrics();
  }

   void clearTimeRange() {
    _fromDate = DateTime(0);
    _toDate = DateTime(0);
    selectedRange = '';
    notifyListeners(); // Notify UI that time range is cleared
  }
  
  // Format dates without timezone conversion
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // Fetch metrics from API
  Future<void> fetchMetrics({String? ipAddress}) async {
    if (ipAddress == null && _currentIpAddress.isEmpty) {
      _error = 'No IP address specified';
      notifyListeners();
      return;
    }
    
    final String targetIp = ipAddress ?? _currentIpAddress;
    _currentIpAddress = targetIp; // Store for future refreshes
    
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final fromTimeStr = _formatDateTime(_fromDate);
      final toTimeStr = _formatDateTime(_toDate);

      print('Sending time range fetchmetrics: $fromTimeStr to $toTimeStr');

      final uri = Uri.parse('${Constants.baseIpAddress}/machine-metrics/$targetIp')
          .replace(queryParameters: {
        'fromTime': fromTimeStr,
        'toTime': toTimeStr,
      });

      print('Request URL fetchmetrics: $uri');

      final response = await http.get(uri);

      print('Response status code fetch metric: ${response.statusCode}');
      print('Response body fetch metrics: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['debug'] != null) {
          print('Debug info from server fetch metrics: ${data['debug']}');
        }
        final List<dynamic> metricsData = data['metrics'] as List? ?? [];

        if (metricsData.isEmpty) {
          _metrics = [];
          _error = 'No data found for the selected time period';
     
          notifyListeners();
          return;
        }

          _metrics = metricsData.map((item) => MetricsData.fromJson(item)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        print('Loaded ${_metrics.length} metrics');
        if (_metrics.isNotEmpty) {
          print('Time range in response fetchmetrics: '
              '${_metrics.first.timestamp} to ${_metrics.last.timestamp}');
        }

        _error = '';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Unknown error');
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

Future<void> fetchMetricstable({String? ipAddress}) async {
  if ((ipAddress?.isEmpty ?? true) && _currentIpAddress.isEmpty) {
    _error = 'No IP address specified';
    notifyListeners();
    return;
  }

  final String targetIp = ipAddress ?? _currentIpAddress;
  _currentIpAddress = targetIp; // Store for future refreshes

  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    final fromTimeStr = _formatDateTime(_fromDate);
    final toTimeStr = _formatDateTime(_toDate);

    print('Sending time range: $fromTimeStr to $toTimeStr');

    final uri = Uri.parse('${Constants.baseIpAddress}/machine-metrics-table/$targetIp')
        .replace(queryParameters: {
      'fromTime': fromTimeStr,
      'toTime': toTimeStr,
    });

    print('Request URL mold: $uri');

    final response = await http.get(uri);

    print('Response status code mold: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['debug'] != null) {
        print('Debug info from server mold: ${data['debug']}');
      }

      final List<dynamic> metricsData = (data['metrics'] as List?) ?? [];

      if (metricsData.isEmpty) {
        _metricstable = [];
        _error = 'No data found for the selected time period';
        notifyListeners();
        return;
      }

      _metricstable = metricsData.map((item) => MetricsDataTAble.fromJson(item)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('Loaded ${_metricstable.length} metrics');
      if (_metricstable.isNotEmpty) {
        print('Time range in response: '
            '${_metricstable.first.timestamp} to ${_metricstable.last.timestamp}');
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


  Future<void> fetchmoldMetrics({String? ipAddress}) async {
  if ((ipAddress?.isEmpty ?? true) && _currentIpAddress.isEmpty) {
    _error = 'No IP address specified';
    notifyListeners();
    return;
  }

  final String targetIp = ipAddress ?? _currentIpAddress;
  _currentIpAddress = targetIp; // Store for future refreshes

  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    final fromTimeStr = _formatDateTime(_fromDate);
    final toTimeStr = _formatDateTime(_toDate);

    print('Sending time range: $fromTimeStr to $toTimeStr');

    final uri = Uri.parse('${Constants.baseIpAddress}/machine-metrics-moldwise/$targetIp')
        .replace(queryParameters: {
      'fromTime': fromTimeStr,
      'toTime': toTimeStr,
    });

    print('Request URL mold: $uri');

    final response = await http.get(uri);

    print('Response status code mold: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['debug'] != null) {
        print('Debug info from server mold: ${data['debug']}');
      }

      final List<dynamic> metricsData = (data['metrics'] as List?) ?? [];

      if (metricsData.isEmpty) {
        _metricsmold = [];
        _error = 'No data found for the selected time period';
        notifyListeners();
        return;
      }

      _metricsmold = metricsData.map((item) => MetricsmoldData.fromJson(item)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('Loaded ${_metricsmold.length} metrics');
      if (_metricsmold.isNotEmpty) {
        print('Time range in response: '
            '${_metricsmold.first.timestamp} to ${_metricsmold.last.timestamp}');
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

  
  // Store the current IP address for refreshes
  String _currentIpAddress = '';
}