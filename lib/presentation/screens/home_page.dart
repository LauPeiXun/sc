import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sc/presentation/screens/main_tabs_screen.dart';
import 'package:sc/presentation/components/nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _mode = 'Overall';
  final String _staffId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Stream<QuerySnapshot> _receiptStream;

  @override
  void initState() {
    super.initState();
    _receiptStream = FirebaseFirestore.instance
        .collection('receipt')
        .where('staffId', isEqualTo: _staffId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_staffId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dashboard")),
        body: const Center(
          child: Text('Please log in to view dashboard'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _mode,
            items: ['Overall', 'Day', 'Month', 'Year'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _mode = value);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _receiptStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(docs),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey,
                      width: 0.5,
                    )
                  ),
                  child: Column(
                    children: [
                      const Text("Scans Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildBarChart(docs),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey,
                        width: 0.5,
                      )
                  ),
                  child: Column(
                    children: [
                      const Text("Receipts Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildStatusPieChart(docs),

                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MainTabsScreen(initialIndex: index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(List<QueryDocumentSnapshot> docs) {
    final filteredDocs = _filterDocs(docs);
    int clearCount = 0;
    int unclearCount = 0;
    for (var doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      String status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'clear') {
        clearCount++;
      } else {
        unclearCount++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row (
          children: [
            Expanded(child: _buildInfoCard("Total Scans", "${docs.length}", Icons.document_scanner, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard(_mode, "${_filterDocs(docs).length}", Icons.analytics, Colors.orange)),
          ],
        ),
        Row (
          children: [
            Expanded(child: _buildInfoCard(" Clear", "$clearCount", Icons.done_outline_outlined, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard("Unclear", "$unclearCount", Icons.error_outline, Colors.red)),
          ],
        )
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    return docs.where((doc) {
      final date = (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      if (_mode == 'Overall') return true;
      if (_mode == 'Day') return date.day == now.day && date.month == now.month && date.year == now.year;
      if (_mode == 'Month') return date.month == now.month && date.year == now.year;
      return date.year == now.year;
    }).toList();
  }

  Widget _buildBarChart(List<QueryDocumentSnapshot> docs) {
    Map<String, int> data = {};
    final now = DateTime.now();

    for (var doc in docs) {
      final date = (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      String key = "";
      if (_mode == 'Overall') {
        key = DateFormat('MMM yyyy').format(date);
      } else if (_mode == 'Day') {
        if (date.month == now.month && date.year == now.year) {
          key = DateFormat('dd').format(date);
        }
      } else if (_mode == 'Month') {
        if (date.year == now.year) {
          key = DateFormat('MMM').format(date);
        }
      } else {
        key = DateFormat('yyyy').format(date);
      }
      if (key.isNotEmpty) data[key] = (data[key] ?? 0) + 1;
    }

    List<BarChartGroupData> groups = [];
    int i = 0;
    data.forEach((key, value) {
      groups.add(BarChartGroupData(x: i++, barRods: [BarChartRodData(toY: value.toDouble(), color: Colors.blue, width: 16)]));
    });

    return SizedBox(
      height: 200,

      child: BarChart(
        BarChartData(
          barGroups: groups,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.keys.length) {
                    return Text(data.keys.elementAt(value.toInt()), style: const TextStyle(fontSize: 10));
                  }
                  return const Text("");
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(List<QueryDocumentSnapshot> docs) {
    int clearCount = 0;
    int unclearCount = 0;
    final filtered = _filterDocs(docs);

    for (var doc in filtered) {
      final data = doc.data() as Map<String, dynamic>;
      String status = data['status'] ?? '';

      if (status == 'clear') {
        clearCount++;
      } else {
        unclearCount++;
      }
    }

    if (clearCount == 0 && unclearCount == 0) {
      return const Center(child: Text("No data for status analysis"));
    }

    List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: clearCount.toDouble(),
        title: 'Clear\n$clearCount',
        color: Colors.green,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: unclearCount.toDouble(),
        title: 'Unclear\n$unclearCount',
        color: Colors.red,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}