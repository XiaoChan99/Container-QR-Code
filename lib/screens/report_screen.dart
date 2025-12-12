import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'week';
  Map<String, int> _priorityStats = {};
  Map<String, int> _statusStats = {};
  Map<String, int> _cargoTypeStats = {};
  int _totalContainers = 0;
  int _averageContainersPerDay = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      if (_selectedPeriod == 'week') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'month') {
        startDate = DateTime(now.year, now.month - 1, now.day);
      } else {
        startDate = DateTime(now.year, now.month, now.day);
      }

      final query = await _firestore
          .collection('Containers')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      Map<String, int> priorityMap = {};
      Map<String, int> statusMap = {};
      Map<String, int> cargoTypeMap = {};

      // Define statuses to exclude
      final excludedStatuses = ['delivered', 'accepted', 'inprogress', 'in transit', 'completed'];
      
      for (var doc in query.docs) {
        final data = doc.data();
        
        // Priority stats
        final priority = data['priority']?.toString().toLowerCase() ?? 'unknown';
        priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;

        // Status stats - only include non-delivery related statuses
        final status = data['status']?.toString().toLowerCase() ?? 'unknown';
        
        // Only include if status is NOT in excluded list
        bool shouldExclude = false;
        for (var excluded in excludedStatuses) {
          if (status.contains(excluded)) {
            shouldExclude = true;
            break;
          }
        }
        
        if (!shouldExclude) {
          // Format status for display (capitalize first letter)
          final displayStatus = status.isNotEmpty 
              ? status[0].toUpperCase() + status.substring(1)
              : 'Unknown';
          statusMap[displayStatus] = (statusMap[displayStatus] ?? 0) + 1;
        }

        // Cargo type stats
        final cargoType = data['cargoType']?.toString().toLowerCase() ?? 'unknown';
        cargoTypeMap[cargoType] = (cargoTypeMap[cargoType] ?? 0) + 1;
      }

      final daysInPeriod = _selectedPeriod == 'week'
          ? 7
          : _selectedPeriod == 'month'
              ? 30
              : 1;

      setState(() {
        _priorityStats = priorityMap;
        _statusStats = statusMap;
        _cargoTypeStats = cargoTypeMap;
        _totalContainers = query.size;
        _averageContainersPerDay = daysInPeriod > 0 ? (_totalContainers / daysInPeriod).ceil() : _totalContainers;
      });
    } catch (e) {
      print('Error loading report data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1a3a6b),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPeriodSelector(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStats(),
                  const SizedBox(height: 24),
                  _buildPriorityChart(),
                  const SizedBox(height: 24),
                  _buildStatusChart(),
                  const SizedBox(height: 24),
                  _buildCargoTypeChart(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Today', 'today'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton('This Week', 'week'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton('This Month', 'month'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
        _loadReportData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1a3a6b)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1a3a6b),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Total Containers',
                _totalContainers.toString(),
                Colors.blue,
                Icons.inventory_2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Avg. Per Day',
                _averageContainersPerDay.toString(),
                Colors.green,
                Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChart() {
    return _buildChartCard(
      title: 'Containers by Priority',
      icon: Icons.flag,
      stats: _priorityStats,
      colors: [
        Colors.red.shade400,
        Colors.orange.shade400,
        Colors.yellow.shade600,
        Colors.green.shade400,
      ],
    );
  }

  Widget _buildStatusChart() {
    return _buildChartCard(
      title: 'Containers by Status',
      icon: Icons.info_outline,
      stats: _statusStats,
      colors: [
        Colors.blue.shade400,
        Colors.green.shade400,
        Colors.orange.shade400,
        Colors.red.shade400,
        Colors.purple.shade400,
      ],
    );
  }

  Widget _buildCargoTypeChart() {
    return _buildChartCard(
      title: 'Containers by Cargo Type',
      icon: Icons.inventory_2,
      stats: _cargoTypeStats,
      colors: [
        Colors.purple.shade400,
        Colors.cyan.shade400,
        Colors.indigo.shade400,
        Colors.pink.shade400,
        Colors.teal.shade400,
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Map<String, int> stats,
    required List<Color> colors,
  }) {
    // Format keys for display
    final Map<String, int> formattedStats = {};
    stats.forEach((key, value) {
      if (key.isNotEmpty) {
        final formattedKey = key[0].toUpperCase() + key.substring(1);
        formattedStats[formattedKey] = value;
      } else {
        formattedStats['Unknown'] = value;
      }
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a3a6b).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1a3a6b), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a3a6b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (formattedStats.isEmpty)
              Center(
                child: Text(
                  'No data available',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              )
            else
              Column(
                children: List.from(formattedStats.entries).asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value.key;
                  final count = entry.value.value;
                  final total = formattedStats.values.reduce((a, b) => a + b);
                  final percentage = (count / total * 100).toStringAsFixed(1);
                  final color = colors[index % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Text(
                              '$count (${percentage}%)',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: count / total,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}