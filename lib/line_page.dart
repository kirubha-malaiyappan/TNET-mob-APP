import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:login_page/machine_details.dart';
import 'package:login_page/providers/line_provider.dart';

class LinesPage extends StatefulWidget {
  final String factoryName;
  final String shopFloorName;

  const LinesPage({
    super.key,
    required this.factoryName,
    required this.shopFloorName,
  });

  @override
  _LinesPageState createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  late LineProvider _lineProvider;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lineProvider = Provider.of<LineProvider>(context, listen: false);
      _lineProvider.initializeAndFetch(widget.factoryName, widget.shopFloorName);
    });
  }

  Widget _buildMachineCard(Map<String, dynamic> machine, LineProvider provider) {
    final color = provider.getColorFromCode(machine['colorCode']);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetails(
              machine: {
                ...machine,
                'ipAddress': machine['ipAddress'],
              },
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.precision_manufacturing, size: 40, color: color),
            SizedBox(height: 18),
            Text(
              machine['machineName'] ?? 'Unknown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(provider.getStatusIcon(machine['colorCode']), color: color, size: 16),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      machine['machineStatus'],
                      style: TextStyle(
                        color: color, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              machine['ipAddress'] ?? 'No IP',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Production Lines'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LineProvider>(context, listen: false)
                .fetchProductionLines(widget.factoryName, widget.shopFloorName);
              Provider.of<LineProvider>(context, listen: false)
                .fetchOverallPlantOEE(widget.factoryName, widget.shopFloorName);
                Provider.of<LineProvider>(context, listen: false)
                .fetchAVGPlantOEE(widget.factoryName, widget.shopFloorName);
            },
            tooltip: 'Reload Production Lines',
          ),
        ],
      ),
      body: Consumer<LineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text(provider.errorMessage));
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine List
                ListView.builder(
                  shrinkWrap: true,  // Important to make it work inside Column
                  physics: NeverScrollableScrollPhysics(),  // Prevents nested scroll issue
                  itemCount: provider.productionLines.length,
                  itemBuilder: (context, index) {
                    final lineId = provider.productionLines.keys.elementAt(index);
                    final machines = provider.productionLines[lineId] ?? [];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Production Line $lineId',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: machines.map((machine) => 
                              _buildMachineCard(machine, provider)
                            ).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(padding: const EdgeInsets.all(16),
                
                    child: Consumer<LineProvider>(
                                builder: (context, provider, child) {
                                  if (provider.isLoading) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (provider.avgPlantOee.isEmpty) {
                                    return const Center(child: Text("No average metrics available"));
                                  }
                                  final latestMetrics = provider.avgPlantOee.isNotEmpty  ? provider.avgPlantOee.first : null;
                    
                                  if (latestMetrics == null) {
                                    return const Center(child: Text("No average metrics available"));
                                      }
                              
                    
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      //mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Average OEE Metrics',
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
                                              latestMetrics.avgutilization,
                                              Colors.orange,
                                            ),
                                            _buildMetricCircle(
                                              'Productivity',
                                              latestMetrics.avgproductivity,
                                              Colors.green,
                                            ),
                                            _buildMetricCircle(
                                              'Quality',
                                              latestMetrics.avgquality,
                                              Colors.red,
                                            ),
                                            _buildMetricCircle(
                                              'OEE',
                                              latestMetrics.avgoee,
                                              Colors.blue,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
                          const SizedBox(height: 20),


                //OEE Table Below ListView
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
                            'Detailed Overall Plant OEE',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          Consumer<LineProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (provider.overallPlantOEE.isEmpty) {
                                return const Center(child: Text("No data available"));
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  children: [
                                    Text('From Time = ${DateFormat('HH:mm').format(provider.overallPlantOEE.first.fromTIME)} - To Time = ${DateFormat('HH:mm').format(provider.overallPlantOEE.first.toTIME)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    DataTable(
                                      columnSpacing: 20,
                                      headingRowHeight: 50,
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      headingRowColor:
                                          WidgetStateColor.resolveWith((states) => Colors.blue),
                                      border: TableBorder.all(color: Colors.black, width: 1),
                                      columns: const [
                                        DataColumn(label: Text('Machine Name')),
                                        DataColumn(label: Text('Good Parts')),
                                        DataColumn(label: Text('Reject Parts')),
                                        DataColumn(label: Text('Energy')),
                                        DataColumn(label: Text('Productivity')),
                                        DataColumn(label: Text('Quality')),
                                        DataColumn(label: Text('Utilization')),
                                        DataColumn(label: Text('OEE')),
                                      ],
                                      rows: provider.overallPlantOEE.map((metric) {
                                        return DataRow(cells: [
                                          DataCell(Text(metric.machinename)),
                                          DataCell(Text('${metric.goodParts}')),
                                          DataCell(Text('${metric.rejectParts}')),
                                          DataCell(Text('${metric.energyconsumption}')),
                                          DataCell(Text('${metric.productivity.toStringAsFixed(2)}%')),
                                          DataCell(Text('${metric.quality.toStringAsFixed(2)}%')),
                                          DataCell(Text('${metric.utilization.toStringAsFixed(2)}%')),
                                          DataCell(Text('${metric.oee.toStringAsFixed(2)}%')),
                                        ]);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          );
        },
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