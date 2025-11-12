import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import '../models/container_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _totalContainers = 0;
  int _readyForRelease = 0;
  int _incidentReported = 0;
  int _todayScans = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get total containers
      final totalQuery = await _firestore.collection('Containers').get();
      
      // Get ready for release containers
      final readyQuery = await _firestore
          .collection('Containers')
          .where('status', isEqualTo: 'ready_for_release')
          .get();
      
      // Get incident reported containers
      final incidentQuery = await _firestore
          .collection('Containers')
          .where('status', isEqualTo: 'incident_reported')
          .get();
      
      // Get today's scans
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayScansQuery = await _firestore
          .collection('Containers')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      setState(() {
        _totalContainers = totalQuery.size;
        _readyForRelease = readyQuery.size;
        _incidentReported = incidentQuery.size;
        _todayScans = todayScansQuery.size;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Navy Header
          _buildHeader(context: context),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildDashboardStats(),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required BuildContext context}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a3a6b),
            const Color(0xFF2d5aa0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.anchor,
                  color: Colors.amber[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PORT CONGESTION',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'MANAGEMENT SYSTEM',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _showLogoutDialog(context),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: const Color(0xFF1a3a6b), size: 28),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a6b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a3a6b),
            const Color(0xFF2d5aa0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1a3a6b).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track and manage container operations efficiently with real-time updates and comprehensive analytics.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: Colors.amber[400], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Live Updates',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 50,
              color: Colors.amber[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1a3a6b),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              title: 'Total Containers',
              value: _totalContainers.toString(),
              icon: Icons.storage,
              color: Colors.blue,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            _buildStatCard(
              title: 'Ready for Release',
              value: _readyForRelease.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
            _buildStatCard(
              title: 'Today\'s Scans',
              value: _todayScans.toString(),
              icon: Icons.qr_code_scanner,
              color: Colors.orange,
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
            ),
            _buildStatCard(
              title: 'Incidents',
              value: _incidentReported.toString(),
              icon: Icons.warning,
              color: Colors.red,
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1a3a6b),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildActionCard(
              title: 'Scan QR Code',
              subtitle: 'Scan container QR codes',
              icon: Icons.qr_code_scanner,
              color: const Color(0xFF1a3a6b),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Scan History',
              subtitle: 'View scan records',
              icon: Icons.history,
              color: Colors.amber[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Container Map',
              subtitle: 'View yard layout',
              icon: Icons.map,
              color: Colors.green.shade600,
              onTap: () {
                // Navigate to container map screen
              },
            ),
            _buildActionCard(
              title: 'Reports',
              subtitle: 'Generate reports',
              icon: Icons.analytics,
              color: Colors.purple.shade600,
              onTap: () {
                // Navigate to reports screen
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1a3a6b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a3a6b),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: const Color(0xFF1a3a6b),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Containers')
              .orderBy('scannedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final containers = snapshot.data!.docs.map((doc) {
              return ContainerData.fromFirestore(doc);
            }).toList();

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: containers.map((container) => _buildActivityItem(container)).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(ContainerData container) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: container.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              container.status.icon,
              color: container.status.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  container.containerId,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1a3a6b),
                  ),
                ),
                Text(
                  'Scanned ${_formatTimeAgo(container.scannedAt)}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: container.priority.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              container.priority.displayName,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: container.priority.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}