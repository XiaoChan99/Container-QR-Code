import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_model.dart';
import 'container_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedTimeFilter = 'all';
  String? _selectedPriorityFilter;
  String? _selectedStatusFilter;
  String? _selectedCargoTypeFilter;
  bool _showFilters = false;
  List<Priority> _availablePriorities = Priority.values;
  List<ContainerStatus> _availableStatuses = ContainerStatus.values;
  List<CargoType> _availableCargoTypes = CargoType.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Container History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1a3a6b),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (_selectedPriorityFilter != null ||
              _selectedStatusFilter != null ||
              _selectedCargoTypeFilter != null)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeFilterBar(),
          if (_showFilters) _buildAdvancedFilters(),
          _buildActiveFiltersChips(),
          _buildRecentActivitySummary(),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPriorityFilter = null;
      _selectedStatusFilter = null;
      _selectedCargoTypeFilter = null;
    });
  }

  Widget _buildActiveFiltersChips() {
    final List<Widget> filterChips = [];

    if (_selectedPriorityFilter != null) {
      filterChips.add(
        _buildActiveFilterChip(
          'Priority: ${_selectedPriorityFilter!}',
          () {
            setState(() {
              _selectedPriorityFilter = null;
            });
          },
          const Color(0xFF1a3a6b),
        ),
      );
    }

    if (_selectedStatusFilter != null) {
      filterChips.add(
        _buildActiveFilterChip(
          'Status: ${_selectedStatusFilter!}',
          () {
            setState(() {
              _selectedStatusFilter = null;
            });
          },
          Colors.green,
        ),
      );
    }

    if (_selectedCargoTypeFilter != null) {
      filterChips.add(
        _buildActiveFilterChip(
          'Cargo: ${_selectedCargoTypeFilter!}',
          () {
            setState(() {
              _selectedCargoTypeFilter = null;
            });
          },
          Colors.orange,
        ),
      );
    }

    if (filterChips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          ...filterChips,
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: onRemove,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildTimeFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTimeFilterChip('All Time', 'all'),
            const SizedBox(width: 8),
            _buildTimeFilterChip('Today', 'today'),
            const SizedBox(width: 8),
            _buildTimeFilterChip('This Week', 'week'),
            const SizedBox(width: 8),
            _buildTimeFilterChip('This Month', 'month'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, String value) {
    final isSelected = _selectedTimeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1a3a6b)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter By:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a3a6b),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Priority',
            _selectedPriorityFilter,
            _availablePriorities.map((p) => p.displayName).toList(),
            (value) {
              setState(() {
                _selectedPriorityFilter = value;
              });
            },
            Icons.flag,
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Status',
            _selectedStatusFilter,
            _availableStatuses.map((s) => s.displayName).toList(),
            (value) {
              setState(() {
                _selectedStatusFilter = value;
              });
            },
            Icons.info_outline,
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Cargo Type',
            _selectedCargoTypeFilter,
            _availableCargoTypes.map((c) => c.displayName).toList(),
            (value) {
              setState(() {
                _selectedCargoTypeFilter = value;
              });
            },
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? currentValue,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF1a3a6b)),
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: const Color(0xFF1a3a6b), size: 20),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All $label',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(color: Colors.black87),
                ),
              );
            }).toList(),
          ],
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Containers')
          .orderBy('containerId', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final lastContainer = ContainerData.fromFirestore(snapshot.data!.docs.first);
        final timeAgo = _formatTimeAgo(lastContainer.scannedAt);

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a3a6b).withOpacity(0.1),
                const Color(0xFF2d5aa0).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1a3a6b).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a3a6b).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: const Color(0xFF1a3a6b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Container: ${lastContainer.containerId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a3a6b),
                      ),
                    ),
                    Text(
                      'Added $timeAgo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lastContainer.priority.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lastContainer.priority.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: lastContainer.priority.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Containers')
          .orderBy('containerId', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF1a3a6b),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(context);
        }

        final allContainers = snapshot.data!.docs.map((doc) {
          return ContainerData.fromFirestore(doc);
        }).toList();

        final filteredContainers = _filterContainers(allContainers);

        if (filteredContainers.isEmpty) {
          return _buildEmptyFilterState();
        }

        return Container(
          color: Colors.grey[50],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredContainers.length} ${filteredContainers.length == 1 ? 'Container' : 'Containers'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a3a6b),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, size: 20),
                      onPressed: _showSortOptions,
                      color: const Color(0xFF1a3a6b),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredContainers.length,
                  itemBuilder: (context, index) {
                    final container = filteredContainers[index];
                    return _buildHistoryCard(context, container);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a3a6b),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Container ID (Newest First)', Icons.numbers),
              _buildSortOption('Container ID (Oldest First)', Icons.numbers),
              _buildSortOption('Priority (High to Low)', Icons.flag),
              _buildSortOption('Status', Icons.info_outline),
              _buildSortOption('Date Added (Newest)', Icons.calendar_today),
              _buildSortOption('Date Added (Oldest)', Icons.calendar_today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1a3a6b)),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        // TODO: Implement sorting logic
      },
    );
  }

  List<ContainerData> _filterContainers(List<ContainerData> containers) {
    // First filter by time
    List<ContainerData> filtered = _filterByTime(containers);
    
    // Then filter by priority
    if (_selectedPriorityFilter != null) {
      filtered = filtered.where((container) {
        return container.priority.displayName == _selectedPriorityFilter;
      }).toList();
    }
    
    // Then filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered.where((container) {
        return container.status.displayName == _selectedStatusFilter;
      }).toList();
    }
    
    // Then filter by cargo type
    if (_selectedCargoTypeFilter != null) {
      filtered = filtered.where((container) {
        return container.cargoType.displayName == _selectedCargoTypeFilter;
      }).toList();
    }
    
    return filtered;
  }

  List<ContainerData> _filterByTime(List<ContainerData> containers) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    return containers.where((container) {
      final scanDate = DateTime(
        container.scannedAt.year,
        container.scannedAt.month,
        container.scannedAt.day,
      );

      switch (_selectedTimeFilter) {
        case 'today':
          return scanDate == today;
        case 'week':
          return scanDate.isAfter(weekAgo) || scanDate == weekAgo;
        case 'month':
          return scanDate.isAfter(monthAgo) || scanDate == monthAgo;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a3a6b).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.history,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Containers Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a3a6b),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Your scanned containers will appear here.\nStart scanning to build your history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Start Scanning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a3a6b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a3a6b).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No containers found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a3a6b),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'No containers match your current filters.\nTry adjusting your filter criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a3a6b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ContainerData container) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContainerDetailScreen(container: container),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1a3a6b),
                          const Color(0xFF2d5aa0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      container.cargoType.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          container.containerId,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a3a6b),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Container #${container.containerNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: container.priority.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: container.priority.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 14,
                          color: container.priority.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          container.priority.displayName,
                          style: TextStyle(
                            color: container.priority.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: container.status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          container.status.icon,
                          size: 12,
                          color: container.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          container.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: container.status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: container.cargoType.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          container.cargoType.icon,
                          size: 12,
                          color: container.cargoType.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          container.cargoType.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: container.cargoType.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Added: ${_formatScanTime(container.scannedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScanTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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