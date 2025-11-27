import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AddContainerData extends StatefulWidget {
  const AddContainerData({super.key});

  @override
  State<AddContainerData> createState() => _AddContainerDataState();
}

class _AddContainerDataState extends State<AddContainerData> {
  bool _isLoading = false;
  bool _showAddContainer = false;
  String? _generatedQRData;
  int _nextContainerId = 1;
  bool _hasGeneratedQR = false;

  // Tracking variables
  List<String> _recentContainers = [];
  String? _lastScannedContainerId;

  // Form Controllers
  final _containerNumberController = TextEditingController();
  final _consignorNameController = TextEditingController();
  final _consignorEmailController = TextEditingController();
  final _consignorAddressController = TextEditingController();
  final _consigneeNameController = TextEditingController();
  final _consigneeEmailController = TextEditingController();
  final _consigneeAddressController = TextEditingController();
  final _billingLadingController = TextEditingController();
  final _sealNoController = TextEditingController();
  final _destinationController = TextEditingController();

  String _selectedPriority = 'medium';
  String _selectedCargoType = 'dry';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadNextContainerId();
  }

  Future<void> _loadNextContainerId() async {
    try {
      setState(() {
        _isLoading = true;
      });

      int highestFirestoreId = await _getHighestContainerIdFromFirestore();
      
      final prefs = await SharedPreferences.getInstance();
      final lastLocalId = prefs.getInt('lastContainerId') ?? 0;
      
      int nextId = (highestFirestoreId > lastLocalId ? highestFirestoreId : lastLocalId);
      
      if (nextId > 0) {
        nextId++;
      } else {
        nextId = 1;
      }
      
      setState(() {
        _nextContainerId = nextId;
        _isLoading = false;
        _hasGeneratedQR = false;
      });
    } catch (e) {
      print('Error loading next container ID: $e');
      setState(() {
        _nextContainerId = 1;
        _isLoading = false;
        _hasGeneratedQR = false;
      });
    }
  }

  Future<int> _getHighestContainerIdFromFirestore() async {
    try {
      final querySnapshot = await _firestore
          .collection('Containers')
          .get();

      int highestId = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        if (data.containsKey('containerId')) {
          final containerIdStr = data['containerId'].toString();
          final containerId = int.tryParse(containerIdStr);
          if (containerId != null && containerId > highestId) {
            highestId = containerId;
          }
        }
        
        final docId = int.tryParse(doc.id);
        if (docId != null && docId > highestId) {
          highestId = docId;
        }
      }
      
      return highestId;
    } catch (e) {
      print('Error getting highest container ID from Firestore: $e');
      return 0;
    }
  }

  Future<void> _saveLastContainerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastContainerId', _nextContainerId);
    } catch (e) {
      print('Error saving last container ID: $e');
    }
  }

  // Universal download method that works on all platforms
  Future<void> _downloadQRCode(Uint8List qrImageBytes, int containerId) async {
    try {
      // For web, use a different approach
      if (kIsWeb) {
        _downloadForWeb(qrImageBytes, containerId);
      } else {
        // For mobile, use file system
        await _downloadForMobile(qrImageBytes, containerId);
      }
    } catch (e) {
      print('Error saving QR code: $e');
      _showErrorDialog('Error saving QR code. Please use the manual download option.');
    }
  }

  // Check if running on web
  bool get kIsWeb => identical(0, 0.0);

  // Download method for Web using data URLs
  void _downloadForWeb(Uint8List qrImageBytes, int containerId) {
    try {
      // Convert bytes to base64
      final base64 = _bytesToBase64(qrImageBytes);
      final dataUrl = 'data:image/png;base64,$base64';
      
      // Create a temporary anchor element for download
      _downloadFromDataUrl(dataUrl, 'container_${containerId}_qr.png');
      
      _showDownloadSuccessDialog('Downloads Folder', 'Web Browser');
    } catch (e) {
      print('Web download failed: $e');
      _showManualDownloadInstructions();
    }
  }

  // Convert bytes to base64 for web
  String _bytesToBase64(Uint8List bytes) {
    final values = bytes.map((byte) => String.fromCharCode(byte)).join('');
    return _base64Encode(values);
  }

  // Base64 encoding for web
  String _base64Encode(String input) {
    try {
      // For web, we'll use a simple base64 encoding
      final base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      final result = StringBuffer();
      int i = 0;
      
      while (i < input.length) {
        final a = i < input.length ? input.codeUnitAt(i++) : 0;
        final b = i < input.length ? input.codeUnitAt(i++) : 0;
        final c = i < input.length ? input.codeUnitAt(i++) : 0;
        
        final bitmap = (a << 16) | (b << 8) | c;
        
        result.write(base64Chars[(bitmap >> 18) & 63]);
        result.write(base64Chars[(bitmap >> 12) & 63]);
        result.write(base64Chars[(bitmap >> 6) & 63]);
        result.write(base64Chars[bitmap & 63]);
      }
      
      // Handle padding
      final padding = input.length % 3;
      if (padding > 0) {
        result.write('=='.substring(0, 3 - padding));
      }
      
      return result.toString();
    } catch (e) {
      // Fallback: try to launch the image in a new tab
      _showManualDownloadInstructions();
      return '';
    }
  }

  // Download using data URL - web compatible approach
  void _downloadFromDataUrl(String dataUrl, String fileName) {
    try {
      // For web, we'll open the image in a new tab and let user save it manually
      launchUrl(Uri.parse(dataUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Failed to launch URL: $e');
      _showManualDownloadInstructions();
    }
  }

  // Download method for Mobile
  Future<void> _downloadForMobile(Uint8List qrImageBytes, int containerId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/container_${containerId}_qr.png';
      final file = File(filePath);
      
      await file.writeAsBytes(qrImageBytes);
      _showDownloadSuccessDialog(filePath, 'Documents Folder');
      print('QR code saved to: $filePath');
    } catch (e) {
      print('Mobile download failed: $e');
      _showErrorDialog('Error saving QR code: ${e.toString()}');
    }
  }

  // Show manual download instructions
  void _showManualDownloadInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download Instructions', style: TextStyle(color: Color(0xFF1a3a6b))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: Colors.orange, size: 50),
            SizedBox(height: 16),
            Text(
              'To download the QR code:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '1. Right-click on the QR code image\n'
              '2. Select "Save image as..."\n'
              '3. Choose where to save the file\n'
              '4. Name it "container_[ID]_qr.png"',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'The image will open in a new tab. Use your browser\'s save option.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFF1a3a6b))),
          ),
        ],
      ),
    );
  }

  void _showDownloadSuccessDialog(String location, String locationType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Downloaded!', style: TextStyle(color: Color(0xFF1a3a6b))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 16),
            Text(
              'QR code has been downloaded successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.download_done, color: Colors.green.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationType == 'Web Browser' 
                        ? 'Check your browser downloads folder'
                        : 'File saved to: $location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFF1a3a6b))),
          ),
        ],
      ),
    );
  }

  void _generateQRCode() async {
    if (!_validateForm()) {
      print('Form validation failed');
      return;
    }

    final currentContainerId = _nextContainerId;
    final qrData = '''Container ID: ${currentContainerId}
Container Number: ${_containerNumberController.text}
Priority: $_selectedPriority
Cargo Type: $_selectedCargoType
Consignor: ${_consignorNameController.text}
Consignor Email: ${_consignorEmailController.text}
Consignor Address: ${_consignorAddressController.text}
Consignee: ${_consigneeNameController.text}
Consignee Email: ${_consigneeEmailController.text}
Consignee Address: ${_consigneeAddressController.text}
Bill of Lading: ${_billingLadingController.text}
Seal Number: ${_sealNoController.text}
Destination: ${_destinationController.text}
Generated on: ${DateTime.now().toString()}''';

    setState(() {
      _generatedQRData = qrData;
      _recentContainers.add(currentContainerId.toString());
      if (_recentContainers.length > 1000) {
        _recentContainers.removeAt(0);
      }
      _lastScannedContainerId = currentContainerId.toString();
      _hasGeneratedQR = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF1a3a6b),
        ),
      ),
    );

    try {
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF1a3a6b),
        emptyColor: Colors.white,
      ).toImageData(300.0);
      
      if (mounted) {
        Navigator.pop(context);
        
        if (qrImage != null) {
          final qrImageBytes = qrImage.buffer.asUint8List();
          _showQRCodeDialog(qrData, qrImageBytes, currentContainerId);
          
          setState(() {
            _nextContainerId++;
          });
          await _saveLastContainerId();
        } else {
          _showErrorDialog('Failed to generate QR code image');
        }
      }
    } catch (e) {
      print('Error generating QR code: $e');
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error generating QR code: $e');
      }
    }
  }

  bool _validateForm() {
    if (_containerNumberController.text.isEmpty) {
      _showErrorDialog('Please enter container number');
      return false;
    }
    if (_consignorNameController.text.isEmpty) {
      _showErrorDialog('Please enter consignor name');
      return false;
    }
    if (_consignorEmailController.text.isEmpty ||
        !_isValidEmail(_consignorEmailController.text)) {
      _showErrorDialog('Please enter valid consignor email');
      return false;
    }
    if (_consignorAddressController.text.isEmpty) {
      _showErrorDialog('Please enter consignor address');
      return false;
    }
    if (_consigneeNameController.text.isEmpty) {
      _showErrorDialog('Please enter consignee name');
      return false;
    }
    if (_consigneeEmailController.text.isEmpty ||
        !_isValidEmail(_consigneeEmailController.text)) {
      _showErrorDialog('Please enter valid consignee email');
      return false;
    }
    if (_consigneeAddressController.text.isEmpty) {
      _showErrorDialog('Please enter consignee address');
      return false;
    }
    if (_billingLadingController.text.isEmpty) {
      _showErrorDialog('Please enter bill of lading number');
      return false;
    }
    if (_sealNoController.text.isEmpty) {
      _showErrorDialog('Please enter seal number');
      return false;
    }
    if (_destinationController.text.isEmpty) {
      _showErrorDialog('Please enter destination');
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _showQRCodeDialog(String qrData, Uint8List qrImageBytes, int containerId) {
    int containerSequence = _recentContainers.indexOf(containerId.toString()) + 1;
    String sequenceText = _getSequenceText(containerSequence);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR Code Generated Successfully!',
                  style: TextStyle(
                    color: const Color(0xFF1a3a6b),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'This is your $sequenceText container',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Container ID: $containerId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a3a6b),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Container Number: ${_containerNumberController.text}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SizedBox(
                    width: 250.0,
                    height: 250.0,
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'QR code contains all container data. Scan this QR code to save the container to the database.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use the Scan Screen to scan this QR code and save container data',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _downloadQRCode(qrImageBytes, containerId);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        _resetForm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a3a6b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Alternative download instruction for web
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Tip: Right-click on the QR code and select "Save image as..."',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSequenceText(int sequence) {
    if (sequence >= 1 && sequence <= 10) {
      switch (sequence) {
        case 1: return 'first';
        case 2: return 'second';
        case 3: return 'third';
        case 4: return 'fourth';
        case 5: return 'fifth';
        case 6: return 'sixth';
        case 7: return 'seventh';
        case 8: return 'eighth';
        case 9: return 'ninth';
        case 10: return 'tenth';
      }
    } else if (sequence >= 11 && sequence <= 20) {
      switch (sequence) {
        case 11: return 'eleventh';
        case 12: return 'twelfth';
        case 13: return 'thirteenth';
        case 14: return 'fourteenth';
        case 15: return 'fifteenth';
        case 16: return 'sixteenth';
        case 17: return 'seventeenth';
        case 18: return 'eighteenth';
        case 19: return 'nineteenth';
        case 20: return 'twentieth';
      }
    } else if (sequence == 21) return 'twenty-first';
    else if (sequence == 22) return 'twenty-second';
    else if (sequence == 23) return 'twenty-third';
    else if (sequence == 24) return 'twenty-fourth';
    else if (sequence == 25) return 'twenty-fifth';
    else if (sequence == 26) return 'twenty-sixth';
    else if (sequence == 27) return 'twenty-seventh';
    else if (sequence == 28) return 'twenty-eighth';
    else if (sequence == 29) return 'twenty-ninth';
    else if (sequence == 30) return 'thirtieth';
    else if (sequence == 31) return 'thirty-first';
    else if (sequence == 32) return 'thirty-second';
    else if (sequence == 33) return 'thirty-third';
    else if (sequence == 40) return 'fortieth';
    else if (sequence == 50) return 'fiftieth';
    else if (sequence == 60) return 'sixtieth';
    else if (sequence == 70) return 'seventieth';
    else if (sequence == 80) return 'eightieth';
    else if (sequence == 90) return 'ninetieth';
    else if (sequence == 100) return 'hundredth';
    else if (sequence == 200) return 'two hundredth';
    else if (sequence == 300) return 'three hundredth';
    else if (sequence == 400) return 'four hundredth';
    else if (sequence == 500) return 'five hundredth';
    else if (sequence == 600) return 'six hundredth';
    else if (sequence == 700) return 'seven hundredth';
    else if (sequence == 800) return 'eight hundredth';
    else if (sequence == 900) return 'nine hundredth';
    else if (sequence == 1000) return 'thousandth';
    
    return '$sequence-th';
  }

  void _resetForm() {
    _containerNumberController.clear();
    _consignorNameController.clear();
    _consignorEmailController.clear();
    _consignorAddressController.clear();
    _consigneeNameController.clear();
    _consigneeEmailController.clear();
    _consigneeAddressController.clear();
    _billingLadingController.clear();
    _sealNoController.clear();
    _destinationController.clear();
    setState(() {
      _selectedPriority = 'medium';
      _selectedCargoType = 'dry';
      _generatedQRData = null;
      _showAddContainer = false;
      _lastScannedContainerId = null;
      _hasGeneratedQR = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.error_outline, color: Colors.red[700], size: 40),
        title: const Text(
          'Error',
          style: TextStyle(
            color: Color(0xFF1a3a6b),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
              ),
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
          'Add Container Data',
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF1a3a6b),
              ),
            )
          : _showAddContainer
              ? _buildAddContainerForm()
              : _buildAddContainerButton(),
    );
  }

  // ... (rest of your build methods remain exactly the same)
  Widget _buildAddContainerButton() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
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
                Icons.add_box_outlined,
                size: 100,
                color: Colors.amber[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Add New Container',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a3a6b),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Create a new container entry with QR code generation. Fill out the form to generate a scannable QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAddContainer = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Container'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a3a6b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContainerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Container ID: $_nextContainerId',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              'Container Number',
              _containerNumberController,
              Icons.numbers,
              hint: 'e.g., C98765',
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              'Priority',
              _selectedPriority,
              ['low', 'medium', 'high', 'urgent'],
              (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              'Cargo Type',
              _selectedCargoType,
              ['dry', 'refrigerated', 'hazardous', 'open_top', 'perishable', 'bulk', 'containerized', 'fragile', 'liquid', 'general'],
              (value) {
                setState(() {
                  _selectedCargoType = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Consignor Information'),
            _buildTextField(
              'Consignor Name',
              _consignorNameController,
              Icons.person_outline,
              hint: 'Full name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Consignor Email',
              _consignorEmailController,
              Icons.email_outlined,
              hint: 'email@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Consignor Address',
              _consignorAddressController,
              Icons.location_on_outlined,
              hint: 'Full address',
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Consignee Information'),
            _buildTextField(
              'Consignee Name',
              _consigneeNameController,
              Icons.person_outline,
              hint: 'Full name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Consignee Email',
              _consigneeEmailController,
              Icons.email_outlined,
              hint: 'email@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Consignee Address',
              _consigneeAddressController,
              Icons.location_on_outlined,
              hint: 'Full address',
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Shipping Details'),
            _buildTextField(
              'Bill of Lading Number',
              _billingLadingController,
              Icons.receipt_outlined,
              hint: 'e.g., BOL123456',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Seal Number',
              _sealNoController,
              Icons.lock_outline,
              hint: 'e.g., SEAL789',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Destination',
              _destinationController,
              Icons.location_on_outlined,
              hint: 'e.g., New York, USA',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateQRCode,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Generate QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a3a6b),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1a3a6b),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _containerNumberController.dispose();
    _consignorNameController.dispose();
    _consignorEmailController.dispose();
    _consignorAddressController.dispose();
    _consigneeNameController.dispose();
    _consigneeEmailController.dispose();
    _consigneeAddressController.dispose();
    _billingLadingController.dispose();
    _sealNoController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}