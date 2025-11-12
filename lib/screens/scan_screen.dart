import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_model.dart';
import 'container_detail_screen.dart';
import 'dart:async'; 

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool isProcessing = false;
  MobileScannerController? _mobileScannerController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _recentlyScanned = {};
  Timer? _clearRecentTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileScannerController = MobileScannerController(
        autoStart: true,
      );
    }
    
    _clearRecentTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _recentlyScanned.clear();
    });
  }

  @override
  void dispose() {
    _mobileScannerController?.dispose();
    _clearRecentTimer?.cancel();
    super.dispose();
  }

  void _processScannedData(String qrData) {
    if (isProcessing) return;
    
    print('Processing scanned data: $qrData');
    
    final Map<String, dynamic> parsedData = _parseQRData(qrData);
    final String containerId = _cleanContainerId(parsedData['containerid']?.toString() ?? qrData);
    
    if (_recentlyScanned.contains(containerId)) {
      print('Container $containerId was recently scanned - ignoring duplicate');
      _showDuplicateScanMessage(containerId);
      return;
    }
    
    setState(() {
      isProcessing = true;
    });

    _showProcessingDialog();

    _sendToFirebase(qrData).then((container) {
      print('Firebase save completed successfully');
      
      _recentlyScanned.add(container.containerId);
      
      Navigator.pop(context);
      _showSuccessMessage(container);
      
    }).catchError((error) {
      print('Firebase save failed: $error');
      Navigator.pop(context);
      _showErrorMessage(error.toString());
      
      setState(() {
        isProcessing = false;
      });
    });
  }

  Future<ContainerData> _sendToFirebase(String qrData) async {
    try {
      final Map<String, dynamic> parsedData = _parseQRData(qrData);
      final container = _createContainerFromQRData(parsedData, qrData);
      
      final DocumentSnapshot existingDoc = await _firestore
          .collection('Containers')
          .doc(container.containerId)
          .get();
      
      if (existingDoc.exists) {
        final existingData = existingDoc.data() as Map<String, dynamic>?;
        final existingTimestamp = existingData?['scannedAt'] as Timestamp?;
        
        if (existingTimestamp != null) {
          final timeDifference = DateTime.now().difference(existingTimestamp.toDate());
          
          if (timeDifference.inMinutes < 5) {
            throw Exception('Container ${container.containerId} was already scanned ${timeDifference.inMinutes} minutes ago');
          }
        }
      }
      
      final containerData = container.toFirestore();

      print('Saving container data: $containerData');

      await _firestore
          .collection('Containers')
          .doc(container.containerId)
          .set(containerData, SetOptions(merge: true));

      print('Container data saved successfully!');
      
      return container;
    } catch (e) {
      print('Error saving to Firebase: $e');
      throw Exception('Failed to save container data: $e');
    }
  }

  Map<String, dynamic> _parseQRData(String qrData) {
    final Map<String, dynamic> parsedData = {};
    
    try {
      if (qrData.contains(':')) {
        final lines = qrData.split('\n');
        for (final line in lines) {
          if (line.contains(':') && !line.contains('===')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim().toLowerCase().replaceAll(' ', '');
              final value = parts.sublist(1).join(':').trim();
              parsedData[key] = value;
            }
          }
        }
      }
      
      if (parsedData.isEmpty) {
        parsedData['containerid'] = qrData;
      }
      
    } catch (e) {
      print('Error parsing QR data: $e');
      parsedData['containerid'] = qrData;
    }
    
    return parsedData;
  }

  ContainerData _createContainerFromQRData(Map<String, dynamic> parsedData, String originalQrData) {
    final random = originalQrData.hashCode;
    final priorities = Priority.values;
    final cargoTypes = CargoType.values;
    final statuses = ContainerStatus.values;

    String containerId = parsedData['containerid']?.toString() ?? 
                        'CON${DateTime.now().millisecondsSinceEpoch}';
    
    containerId = _cleanContainerId(containerId);
    
    String containerNumber = parsedData['containernumber']?.toString() ?? 
                            'C${containerId.length > 3 ? containerId.substring(0, 3) : containerId}';
    
    containerNumber = _cleanContainerNumber(containerNumber);

    final DateTime dateCreated = _parseDate(parsedData['datecreated']?.toString()) ?? 
                                DateTime.now().subtract(Duration(days: random % 30));
    
    final DateTime releaseDate = _parseDate(parsedData['releasedate']?.toString()) ?? 
                                _calculateReleaseDate(
                                  _parseEnumFromString(parsedData['priority']?.toString(), Priority.values) ?? priorities[random % priorities.length],
                                  dateCreated
                                );

    final Priority priority = _parseEnumFromString(parsedData['priority']?.toString(), Priority.values) ?? priorities[random % priorities.length];
    final CargoType cargoType = _parseEnumFromString(parsedData['cargotype']?.toString(), CargoType.values) ?? cargoTypes[random % cargoTypes.length];
    final ContainerStatus status = _parseEnumFromString(parsedData['status']?.toString(), statuses) ?? statuses[random % statuses.length];

    // Generate location data based on container ID for consistency
    final locationData = _generateLocationData(containerId, random);

    return ContainerData(
      containerId: containerId,
      containerNumber: containerNumber,
      voyageId: parsedData['voyageid']?.toString() ?? 'V${(random % 1000).toString().padLeft(3, '0')}',
      priority: priority,
      dateCreated: dateCreated,
      releaseDate: releaseDate,
      cargoType: cargoType,
      status: status,
      location: parsedData['location']?.toString() ?? locationData['location'],
      stackPosition: parsedData['stackposition']?.toString() ?? locationData['stackPosition'],
      tierLevel: int.tryParse(parsedData['tierlevel']?.toString() ?? '') ?? locationData['tierLevel'],
      allocatedBayId: parsedData['allocatedbayid']?.toString() ?? locationData['allocatedBayId'],
      allocationStatus: parsedData['allocationstatus']?.toString() ?? locationData['allocationStatus'],
      scannedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> _generateLocationData(String containerId, int random) {
    final bays = ['bay_1', 'bay_2', 'bay_3', 'bay_4'];
    final stackPositions = ['1_1', '1_2', '2_1', '2_2', '3_1', '3_2'];
    final allocationStatuses = ['pending', 'allocated', 'confirmed', 'released'];
    
    final bay = bays[random % bays.length];
    final stack = stackPositions[random % stackPositions.length];
    final allocationStatus = allocationStatuses[random % allocationStatuses.length];
    
    return {
      'location': '${bay}_${stack}',
      'stackPosition': stack,
      'tierLevel': (random % 5) + 1,
      'allocatedBayId': bay,
      'allocationStatus': allocationStatus,
    };
  }

  DateTime _calculateReleaseDate(Priority priority, DateTime dateCreated) {
    switch (priority) {
      case Priority.urgent:
        return dateCreated;
      case Priority.high:
        return dateCreated.add(const Duration(days: 1));
      case Priority.medium:
        return dateCreated.add(const Duration(days: 3));
      case Priority.low:
        return dateCreated.add(const Duration(days: 5));
      default:
        return dateCreated.add(const Duration(days: 3));
    }
  }

  String _cleanContainerId(String containerId) {
    String cleaned = containerId.replaceAll('Container ID:', '').trim();
    
    if (cleaned.contains(' ')) {
      cleaned = cleaned.split(' ')[0];
    }
    
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    
    if (cleaned.isEmpty) {
      cleaned = 'CON${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return cleaned.length > 20 ? cleaned.substring(0, 20) : cleaned;
  }

  String _cleanContainerNumber(String containerNumber) {
    String cleaned = containerNumber.replaceAll('Container Number:', '').trim();
    
    if (cleaned.contains(' ')) {
      cleaned = cleaned.split(' ')[0];
    }
    
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
    
    if (cleaned.isEmpty) {
      cleaned = 'C${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    
    return cleaned.length > 15 ? cleaned.substring(0, 15) : cleaned;
  }

  T? _parseEnumFromString<T>(String? value, List<T> enumValues) {
    if (value == null) return null;
    
    final cleanValue = value.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    
    for (final enumValue in enumValues) {
      final enumString = _enumToString(enumValue).toLowerCase();
      if (cleanValue.contains(enumString) || enumString.contains(cleanValue)) {
        return enumValue;
      }
    }
    
    return null;
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    
    try {
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }

  String _enumToString(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }

  void _showDuplicateScanMessage(String containerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
        ),
        title: const Text(
          'Already Scanned',
          style: TextStyle(
            color: Color(0xFF1a3a6b),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This container has been recently scanned. Please wait a moment before scanning again.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.tag, color: const Color(0xFF1a3a6b), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      containerId,
                      style: const TextStyle(
                        color: Color(0xFF1a3a6b),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a6b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a3a6b)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Processing Scan...',
              style: TextStyle(
                color: Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saving container data to database',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(ContainerData container) {
    final daysUntilRelease = container.releaseDate.difference(DateTime.now()).inDays;
    final isReleased = daysUntilRelease <= 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
        title: const Text(
          'Scan Successful!',
          style: TextStyle(
            color: Color(0xFF1a3a6b),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Container data has been successfully saved to the database.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.tag, color: const Color(0xFF1a3a6b), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          container.containerId,
                          style: const TextStyle(
                            color: Color(0xFF1a3a6b),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: container.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          container.status.icon,
                          color: container.status.color,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          container.status.displayName,
                          style: TextStyle(
                            color: container.status.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isReleased ? Icons.check_circle : Icons.schedule,
                        color: isReleased ? Colors.green : Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isReleased ? 'Ready for Release' : 'Release in $daysUntilRelease days',
                          style: TextStyle(
                            color: isReleased ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          container.location,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isProcessing = false;
              });
            },
            child: const Text(
              'Scan Again',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ContainerDetailScreen(container: container),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a6b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        ),
        title: const Text(
          'Scan Failed',
          style: TextStyle(
            color: Color(0xFF1a3a6b),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          error.contains('already scanned') 
            ? error 
            : 'Failed to save container data: $error',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isProcessing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a6b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
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
      body: kIsWeb ? _buildWebPlaceholder() : _buildMobileScanner(),
    );
  }

  Widget _buildMobileScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _mobileScannerController!,
          onDetect: (capture) {
            if (isProcessing) return;
            
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processScannedData(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber[600]!, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              _buildControlButton(
                icon: ValueListenableBuilder(
                  valueListenable: _mobileScannerController!.torchState,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => _mobileScannerController?.toggleTorch(),
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                icon: ValueListenableBuilder(
                  valueListenable: _mobileScannerController!.cameraFacingState,
                  builder: (context, state, child) {
                    return Icon(
                      state == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => _mobileScannerController?.switchCamera(),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isProcessing ? 'Processing...' : 'Align QR code within frame',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isProcessing) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Scan to track container location and status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({required Widget icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildWebPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a3a6b).withOpacity(0.1),
            const Color(0xFF2d5aa0).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.amber[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Scanner',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a3a6b),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Camera scanning is only available on mobile devices.\nClick the button below to simulate a scan with complete container data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isProcessing ? null : () {
                _processScannedData('''
Container ID: CON${DateTime.now().millisecondsSinceEpoch}
Container Number: C${DateTime.now().millisecondsSinceEpoch % 10000}
Voyage ID: V${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}
Priority: ${Priority.values[DateTime.now().millisecondsSinceEpoch % Priority.values.length].displayName}
Cargo Type: ${CargoType.values[DateTime.now().millisecondsSinceEpoch % CargoType.values.length].displayName}
Status: ${ContainerStatus.values[DateTime.now().millisecondsSinceEpoch % ContainerStatus.values.length].displayName}
Location: bay_${(DateTime.now().millisecondsSinceEpoch % 4) + 1}_${(DateTime.now().millisecondsSinceEpoch % 3) + 1}_${(DateTime.now().millisecondsSinceEpoch % 2) + 1}
Date Created: ${DateTime.now().subtract(Duration(days: DateTime.now().millisecondsSinceEpoch % 30)).toIso8601String()}
Release Date: ${DateTime.now().add(Duration(days: (DateTime.now().millisecondsSinceEpoch % 10) + 1)).toIso8601String()}
''');
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Simulate QR Scan with Full Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a3a6b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isProcessing) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a3a6b)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Processing simulated scan...',
                style: TextStyle(
                  color: Color(0xFF1a3a6b),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}