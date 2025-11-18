import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout(isSmallScreen, isVerySmallScreen);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Header/Branding
        Expanded(
          flex: 4,
          child: _buildHeaderSection(true),
        ),
        // Right side - Login Form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWelcomeText(true),
                    const SizedBox(height: 40),
                    _buildLoginForm(true),
                    const SizedBox(height: 24),
                    _buildLoginButton(true),
                    const SizedBox(height: 24),
                    _buildSignUpLink(true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isSmallScreen, bool isVerySmallScreen) {
    return Column(
      children: [
        // Top Navy Header Section
        _buildHeaderSection(false),
        // Bottom White Login Section
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 16.0 : 24.0,
                  vertical: isSmallScreen ? 24.0 : 40.0,
                ),
                child: Column(
                  children: [
                    _buildWelcomeText(false),
                    SizedBox(height: isSmallScreen ? 24.0 : 40.0),
                    _buildLoginForm(false),
                    SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                    _buildLoginButton(false),
                    SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                    _buildSignUpLink(false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDesktop) {
    return Container(
      width: isDesktop ? double.infinity : null,
      height: isDesktop ? double.infinity : _calculateHeaderHeight(),
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
            padding: isDesktop 
                ? const EdgeInsets.all(40.0)
                : const EdgeInsets.fromLTRB(24.0, 50.0, 24.0, 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                // Anchor Icon and Title - Centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.anchor,
                      color: Colors.amber[600],
                      size: isDesktop ? 48 : 36,
                    ),
                    SizedBox(width: isDesktop ? 16 : 12),
                    Flexible(
                      child: Text(
                        'PORT CONGESTION MANAGEMENT',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : _calculateTitleFontSize(),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 30 : 20),
                // Tagline with colored words - Centered
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : _calculateTaglineFontSize(),
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
                SizedBox(height: isDesktop ? 20 : 16),
                // Description - Centered and about scanning containers
                Center(
                  child: Text(
                    'Streamline your port operations with advanced\ncontainer scanning and real-time cargo tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : _calculateDescriptionFontSize(),
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 40),
                  // Additional content for desktop
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureItem(Icons.qr_code_scanner, 'QR Scanning', isDesktop),
                        _buildFeatureItem(Icons.analytics, 'Real-time Tracking', isDesktop),
                        _buildFeatureItem(Icons.security, 'Secure Access', isDesktop),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDesktop) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.amber[400],
          size: isDesktop ? 32 : 24,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculateHeaderHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) return screenHeight * 0.35;
    if (screenHeight < 800) return screenHeight * 0.3;
    return screenHeight * 0.28;
  }

  double _calculateTitleFontSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return 16;
    if (screenWidth < 400) return 18;
    return 20;
  }

  double _calculateTaglineFontSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return 12;
    if (screenWidth < 400) return 14;
    return 16;
  }

  double _calculateDescriptionFontSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return 11;
    if (screenWidth < 400) return 12;
    return 14;
  }

  Widget _buildWelcomeText(bool isDesktop) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: isDesktop ? 36 : _calculateWelcomeFontSize(),
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access your shipping dashboard',
          style: TextStyle(
            fontSize: isDesktop ? 16 : _calculateSubtitleFontSize(),
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _calculateWelcomeFontSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return 24;
    if (screenWidth < 400) return 28;
    return 32;
  }

  double _calculateSubtitleFontSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return 12;
    if (screenWidth < 400) return 13;
    return 14;
  }

  Widget _buildLoginForm(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Email Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: isDesktop ? 20 : 16
              ),
              prefixIcon: Icon(
                Icons.email_outlined, 
                color: Colors.grey[700], 
                size: isDesktop ? 26 : 24
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        // Password Label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Password',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Password Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: isDesktop ? 20 : 16
              ),
              prefixIcon: Icon(
                Icons.lock_outline, 
                color: Colors.grey[700], 
                size: isDesktop ? 26 : 24
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 60 : 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1a3a6b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: isDesktop ? 24 : 20,
                width: isDesktop ? 24 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: isDesktop ? 15 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegistrationPage()),
            );
          },
          child: Text(
            'Sign up',
            style: TextStyle(
              color: const Color(0xFF2d5aa0),
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 15 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showLoginError('Please enter both email and password');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showLoginError('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

          // Get user document from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        _showLoginError('User account not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;

      // Check if user has employee role
      if (userRole != 'employee') {
        await _auth.signOut();
        _showLoginError('Access denied. Only employees can login to this app.');
        return;
      }

      // Login successful - navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      }
      
      _showLoginError(errorMessage);
    } catch (e) {
      _showLoginError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Login Failed',
          style: TextStyle(
            color: const Color(0xFF1a3a6b),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: const Color(0xFF1a3a6b),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
    
    // Create wave pattern
    for (int i = 0; i < 5; i++) {
      double startY = size.height * 0.2 + (i * 30);
      path.moveTo(0, startY);
      
      for (double x = 0; x <= size.width; x += 20) {
        path.lineTo(
          x,
          startY + 10 * (i % 2 == 0 ? 1 : -1) * (x / 40).sin(),
        );
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Extension for sin function
extension on double {
  double sin() => 0; // Placeholder - use dart:math for actual implementation
}