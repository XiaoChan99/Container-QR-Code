import 'package:flutter/material.dart';
import '../models/container_model.dart';
import 'scan_screen.dart';

class ContainerDetailScreen extends StatelessWidget {
  final ContainerData container;

  const ContainerDetailScreen({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    final daysUntilRelease = container.releaseDate.difference(DateTime.now()).inDays;
    final isReleased = daysUntilRelease <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Container Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1a3a6b),
        foregroundColor: Colors.white,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReleaseDateBanner(daysUntilRelease, isReleased),
            
            const SizedBox(height: 16),
            
            _buildSectionHeader('Basic Information'),
            _buildInfoCard('Container ID', container.containerId, Icons.tag),
            _buildInfoCard('Container Number', container.containerNumber, Icons.numbers),
            _buildInfoCard('Voyage ID', container.voyageId, Icons.airline_seat_recline_extra),
            
            const SizedBox(height: 8),
            
            _buildSectionHeader('Status & Priority'),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(child: _buildPriorityCard()),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildSectionHeader('Dates'),
            Row(
              children: [
                Expanded(child: _buildDateCard(
                  'Date Created', 
                  container.dateCreated, 
                  Icons.calendar_today,
                  Colors.blue
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildDateCard(
                  'Release Date', 
                  container.releaseDate, 
                  Icons.event_available,
                  isReleased ? Colors.green : Colors.orange
                )),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildSectionHeader('Cargo Information'),
            _buildCargoTypeCard(),
            _buildCargoDetailsCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
            (route) => false,
          );
        },
        backgroundColor: const Color(0xFF1a3a6b),
        foregroundColor: Colors.white,
        child: const Icon(Icons.qr_code_scanner),
        elevation: 4,
      ),
    );
  }

  Widget _buildReleaseDateBanner(int daysUntilRelease, bool isReleased) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReleased ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReleased ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReleased ? Icons.check_circle : Icons.schedule,
            color: isReleased ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReleased ? 'READY FOR RELEASE' : 'SCHEDULED FOR RELEASE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isReleased ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isReleased 
                    ? 'This container is ready to be released'
                    : 'Release in $daysUntilRelease day${daysUntilRelease == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: isReleased ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                Text(
                  _formatDate(container.releaseDate),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isReleased ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1a3a6b),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1a3a6b).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1a3a6b)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(String title, DateTime date, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              _formatTime(date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPriorityCard() {    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: container.priority.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(container.priority.icon, color: container.priority.color, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              container.priority.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: container.priority.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoTypeCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: container.cargoType.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(container.cargoType.icon, color: container.cargoType.color),
        ),
        title: const Text(
          'Cargo Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          container.cargoType.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCargoDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cargo Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1a3a6b),
              ),
            ),
            const SizedBox(height: 12),
            _buildCargoDetailRow('Priority', container.priority.displayName),
            _buildCargoDetailRow('Created', _formatDate(container.dateCreated)),
            _buildCargoDetailRow('Release', _formatDate(container.releaseDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}