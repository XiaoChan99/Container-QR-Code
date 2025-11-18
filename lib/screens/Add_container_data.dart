import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner/screens/container_detail_screen.dart';
import 'container_detail_screen.dart';
import 'dart:html' as html;

class AddContainerData extends StatefulWidget {
  const AddContainerData({super.key});

  @override
  State<AddContainerData> createState() => _AddContainerDataState();
}

class _AddContainerDataState extends State<AddContainerData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _showAddContainer = false;
  String? _generatedQRData;
  int _nextContainerId = 1;

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

  String _selectedPriority = 'medium';
  String _selectedCargoType = 'dry';

  @override
  void initState() {
    super.initState();
    _loadNextContainerId();
  }

  Future<void> _loadNextContainerId() async {
    try {
      final counterDoc = await _firestore.collection('counters').doc('containers').get();
      
      if (counterDoc.exists) {
        setState(() {
          _nextContainerId = counterDoc.data()!['lastId'] + 1;
          _isLoading = false;
        });
      } else {
        // Initialize counter if it doesn't exist
        await _firestore.collection('counters').doc('containers').set({'lastId': 0});
        setState(() {
          _nextContainerId = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading next container ID: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContainerToFirestore(String qrData) async {
    try {
      // Create container data
      final containerData = {
        'containerId': _nextContainerId,
        'containerNumber': _containerNumberController.text,
        'priority': _selectedPriority,
        'cargoType': _selectedCargoType,
        'consignor': {
          'name': _consignorNameController.text,
          'email': _consignorEmailController.text,
          'address': _consignorAddressController.text,
        },
        'consignee': {
          'name': _consigneeNameController.text,
          'email': _consigneeEmailController.text,
          'address': _consigneeAddressController.text,
        },
        'billOfLading': _billingLadingController.text,
        'sealNumber': _sealNoController.text,
        'qrCodeData': qrData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Save container to Firestore
      await _firestore.collection('Containers').doc(_nextContainerId.toString()).set(containerData);

      // Update the counter
      await _firestore.collection('counters').doc('containers').update({
        'lastId': _nextContainerId,
      });

      print('Container saved successfully with ID: $_nextContainerId');
    } catch (e) {
      print('Error saving container to Firestore: $e');
      throw e;
    }
  }

  // For web: Download QR code instead of saving to file
  Future<void> _downloadQRCode(Uint8List qrImageBytes, String containerId) async {
    try {
      final blob = html.Blob([qrImageBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final link = html.AnchorElement(href: url)
        ..setAttribute('download', 'container_${containerId}_qr.png')
        ..click();
      html.Url.revokeObjectUrl(url);
      print('QR code downloaded successfully');
    } catch (e) {
      print('Error downloading QR code: $e');
    }
  }

  void _generateQRCode() async {
    if (!_validateForm()) {
      print('Form validation failed');
      return;
    }

    final qrData = '''Container ID: $_nextContainerId
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
Generated on: ${DateTime.now().toString()}''';

    setState(() {
      _generatedQRData = qrData;
    });

    // Show loading dialog
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
      // Save to Firestore first
      await _saveContainerToFirestore(qrData);

      // Generate QR code image
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF1a3a6b),
        emptyColor: Colors.white,
      ).toImageData(300.0);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (qrImage != null) {
          final qrImageBytes = qrImage.buffer.asUint8List();
          _showQRCodeDialog(qrData, qrImageBytes);
        } else {
          _showErrorDialog('Failed to generate QR code image');
        }
      }
    } catch (e) {
      print('Error generating QR code: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error saving container data: $e');
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
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _showQRCodeDialog(String qrData, Uint8List qrImageBytes) {
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
                  'Container QR Code Generated & Saved!',
                  style: TextStyle(
                    color: const Color(0xFF1a3a6b),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Container ID: $_nextContainerId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a3a6b),
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Container data saved to database successfully!',
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
                const SizedBox(height: 8),
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
                          'QR code contains all container data. Click Download to save it.',
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
                        _downloadQRCode(qrImageBytes, _nextContainerId.toString());
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
              ],
            ),
          ),
        ),
      ),
    );
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
    setState(() {
      _selectedPriority = 'medium';
      _selectedCargoType = 'dry';
      _generatedQRData = null;
      _showAddContainer = false;
    });
    _loadNextContainerId();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.error_outline, color: Colors.red[700], size: 40),
        title: const Text(
          'Validation Error',
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
                  'Next ID: $_nextContainerId',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a3a6b),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showAddContainer = false;
                    });
                    _resetForm();
                  },
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateQRCode,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Generate & Download QR Code'),
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
    super.dispose();
  }
}