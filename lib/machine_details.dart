import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:login_page/providers/machine_metrics_provider.dart';

class MachineDetails extends StatefulWidget {
  final Map<String, dynamic> machine;

  const MachineDetails({super.key, required this.machine});

  @override
  // ignore: library_private_types_in_public_api
  _MachineDetailsState createState() => _MachineDetailsState();
}

class _MachineDetailsState extends State<MachineDetails> {
  late MachineMetricsProvider _metricsProvider;

  @override
  void initState() {
    super.initState();
    
    // Initialize the provider after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsProvider = Provider.of<MachineMetricsProvider>(context, listen: false);
      _metricsProvider.fetchMetrics(ipAddress: widget.machine['ipAddress'] ?? '');
    });
  }
  // void clearData() {
  // metricsdata.clear();
  // metricsmold.clear();
  // notifyListeners();
  // }

  Future<void> _selectDateTime(BuildContext context, bool isFromDate) async {
    final DateTime currentDate = DateTime.now();
    final provider = Provider.of<MachineMetricsProvider>(context, listen: false);
    
    final DateTime initialDate = isFromDate ? provider.fromDate : provider.toDate;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: currentDate,
      selectableDayPredicate: (DateTime date) {
        return date.isBefore(currentDate.add(const Duration(days: 1)));
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (pickedDate.year == currentDate.year &&
            pickedDate.month == currentDate.month &&
            pickedDate.day == currentDate.day) {
          if (combinedDateTime.isAfter(currentDate)) {
            combinedDateTime = currentDate;
          }
        }

        if (isFromDate) {
          provider.setDateRange(combinedDateTime, provider.toDate);
        } else {
          provider.setDateRange(provider.fromDate, combinedDateTime);
        }
        
        provider.fetchMetrics();
        provider.fetchMetricstable();
        provider.fetchmoldMetrics();
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine Details'),
        leading: IconButton(
        icon: const Icon(Icons.arrow_back), 
        onPressed: () {
           //final provider = Provider.of<MachineMetricsProvider>(context, listen: false);
          Navigator.pop(context);
          //provider.clearTimeRange();// Navigate back when pressed
          },
        ),
      ),
      body: Consumer<MachineMetricsProvider>(
        builder: (context, provider, child) {
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.machine['machineName'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Status: ${widget.machine['machineStatus']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  ListTile(
                    title: const Text('From'),
                    subtitle: Text(provider.formatter.format(provider.fromDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, true),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('To'),
                    subtitle: Text(provider.formatter.format(provider.toDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, false),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('1H',const Duration(hours: -1)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == '1H' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == '1H' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('1H'),   
                      ),
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('4H',const Duration(hours: -4)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == '4H' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == '4H' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('4H'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('8H',const Duration(hours: -8)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == '8H' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == '8H' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('8H'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('DAY',const Duration(days: -1)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == 'DAY' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == 'DAY' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('Day'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('WEEK',const Duration(days: -7)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == 'WEEK' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == 'WEEK' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('Week'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.applyTimeRange('MONTHLY',const Duration(days: -30)),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Keep the button color white
                        foregroundColor: Colors.black, // Text color
                        side: BorderSide(
                          color: provider.selectedRange == 'MONTHLY' ? Colors.blue : Colors.grey, // Highlight border when selected
                          width: provider.selectedRange == 'MONTHLY' ? 2.0 : 1.0, // Thicker border for selected button
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                        child: const Text('Month'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  PerformanceMetricsChart(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
}

class PerformanceMetricsChart extends StatelessWidget {
  const PerformanceMetricsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MachineMetricsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading metrics...'),
              ],
            ),
          );
        }

        if (provider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(provider.error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchMetrics(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.metricsdata.isEmpty) {
          return const Center(
            child: Text('No data available for the selected time period'),
          );
        }

        //return CircularMetricsDisplay(metrics: provider.metricsdata);
        return CircularMetricsDisplay(metrics: provider.metricsdata,metricsMold: provider.metricsmold,metricstable: provider.metricstable );
      },
    );
  }
}
// Function to properly format the time
String formatDateTime(String dateTimeString) {
  try {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal(); // Convert UTC to local
    return DateFormat("yyyy-MM-dd hh:mm a").format(dateTime); // Example: 2025-03-05 12:00 PM
  } catch (e) {
    return "Invalid Date"; // Handle errors gracefully
  }
}

class CircularMetricsDisplay extends StatelessWidget {
  final List<MetricsData> metrics;
  final List<MetricsmoldData> metricsMold;
  final List<MetricsDataTAble> metricstable;

  const CircularMetricsDisplay({
    super.key,
    required this.metrics,
    required this.metricsMold,
    required this.metricstable,
  });

  @override
  Widget build(BuildContext context) {
    // Get the latest metrics
    final latestMetrics = metrics.isNotEmpty ? metrics.last : null;
    final latestMetricsmold = metricsMold.isNotEmpty ? metricsMold.last : null;
    final latestMetricstable = metricstable.isNotEmpty ? metrics.last : null;
    // final latestMetrics = metrics.isNotEmpty ? metrics : null;

    if (latestMetrics == null) {
      return const Center(child: Text('No metrics data available'));
    }

    // if (latestMetricsmold == null) {
    //   return const Center(child: Text('No metrics mold data available'));
    // }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Current Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
               _buildMetricCircle(
                'Availability',
                latestMetrics.avgUtilization,
                Colors.orange,
              ),
              _buildMetricCircle(
                'Productivity',
                latestMetrics.avgProductivity,
                Colors.green,
              ),
              _buildMetricCircle(
                'Quality',
                latestMetrics.avgQuality,
                Colors.red,
              ),
              _buildMetricCircle(
                'OEE',
                latestMetrics.avgOEE,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),
      
      /// ✅ Added Table Below Circular Progress Indicators
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Detailed Metrics Table',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 50,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                              ),
                headingRowColor: WidgetStateColor.resolveWith((states) => Colors.blue), // Header background
                border: TableBorder.all(color: Colors.black, width: 1), 
                columns: const [
                  DataColumn(label: Text('From Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('To Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Production', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Quality', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OEE', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                  rows: metricstable.map((metric) {
                  return DataRow(cells: [
                  DataCell(Text(DateFormat('dd/MM/yy HH:00').format(metric.fromtime.toLocal()))), 
                  DataCell(Text(DateFormat('dd/MM/yy HH:00').format(metric.totime.toLocal()))),
                  DataCell(Text('${metric.utilization.toStringAsFixed(2)}%')), // Availability
                  DataCell(Text('${metric.productivity.toStringAsFixed(2)}%')), // Production
                  DataCell(Text('${metric.quality.toStringAsFixed(2)}%')), // Quality
                  DataCell(Text('${metric.oee.toStringAsFixed(2)}%')), // OEE
                ]);
              }).toList(),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      /// ✅ Added Table Below Circular Progress Indicators
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Detailed Mold Metrics Table',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 50,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                              ),
                headingRowColor: WidgetStateColor.resolveWith((states) => Colors.blue), // Header background
                border: TableBorder.all(color: Colors.black, width: 1), 
                columns: const [
                  DataColumn(label: Text('Mold Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Good Parts', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Reject Parts', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total parts', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Material Consumption', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Energy Consumption', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                  rows: metricsMold.map((metric) {
                  return DataRow(cells: [
                  DataCell(Text(metric.moldid)),
                  DataCell(Text('${metric.goodparts}')),
                  DataCell(Text('${metric.rejectparts}')),
                  DataCell(Text('${metric.totalparts}')), // Availability
                  DataCell(Text('${metric.materiallconsumption}')), // Production
                  DataCell(Text('${metric.energyconsumption}')), // OEE
                ]);
              }).toList(),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildMetricCircle(String label, double value, Color color) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.grey[300],
                  color: color,
                  strokeWidth: 10,
                ),
                Center(
                  child: Text(
                    '${value.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
