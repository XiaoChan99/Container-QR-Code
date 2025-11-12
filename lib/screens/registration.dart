import 'package:flutter/material.dart';
import 'login_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String? _selectedRole;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final List<String> _roles = ['Employee'];

  @override
  void initState() {
    super.initState();
    _selectedRole = 'Employee';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Navy Header Section
          _buildHeader(),
          // Bottom White Registration Section
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      _buildCreateAccountText(),
                      const SizedBox(height: 32),
                      _buildRegistrationFormSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      ),
      child: Stack(
        children: [
          // Decorative wave pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: WavePatternPainter(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 50.0, 24.0, 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Anchor Icon and Title - Centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.anchor,
                      color: Colors.amber[600],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PORT CONGESTION MANAGEMENT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tagline with colored words - Centered
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'Track Smarter. ',
                          style: TextStyle(color: Colors.amber[400]),
                        ),
                        TextSpan(
                          text: 'Slot Faster. ',
                          style: TextStyle(color: Colors.green[300]),
                        ),
                        TextSpan(
                          text: 'Ship Worldwide.',
                          style: TextStyle(color: Colors.blue[200]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Description - Centered and about scanning containers
                Center(
                  child: Text(
                    'Streamline your port operations with advanced\ncontainer scanning and real-time cargo tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountText() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our smart port system as an employee',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionSection() {
    return SizedBox.shrink();
  }

  Widget _buildRoleCard(String role) {
    return SizedBox.shrink();
  }

  Widget _buildRegistrationFormSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Selected Role Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1a3a6b).withOpacity(0.1),
                  const Color(0xFF2d5aa0).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2d5aa0).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employee Registration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1a3a6b),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Complete your employee account setup',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildRegistrationForm(),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('First Name', _firstNameController, Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Last Name', _lastNameController, Icons.person_outline)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField('Username', _usernameController, Icons.account_circle_outlined),
        const SizedBox(height: 16),
        _buildTextField('Password', _passwordController, Icons.lock_outline, isPassword: true),
        const SizedBox(height: 16),
        _buildTextField('Confirm Password', _confirmPasswordController, Icons.lock_outline, isPassword: true),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1a3a6b),
              side: BorderSide(color: const Color(0xFF1a3a6b), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Back to Login',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedRole != null ? _completeRegistration : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a6b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: Text(
              'Create Account',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _completeRegistration() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    _showSuccessDialog();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Text(
              'Registration Error',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            Text(
              'Success!',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Your employee account has been created successfully.',
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              'Continue to Login',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// Custom painter for decorative wave pattern
class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    
    for (int i = 0; i < 5; i++) {
      double startY = size.height * 0.2 + (i * 30);
      path.moveTo(0, startY);
      
      for (double x = 0; x <= size.width; x += 20) {
        path.lineTo(x, startY);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}