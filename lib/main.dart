import 'package:flutter/material.dart';
import 'package:qr_scanner/screens/home_screen.dart';
import 'package:qr_scanner/screens/scan_screen.dart';
import 'package:qr_scanner/screens/history_screen.dart';
import 'package:qr_scanner/screens/login_page.dart';
import 'package:qr_scanner/screens/registration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ContainerTrackerApp());
}
class ContainerTrackerApp extends StatelessWidget {
  const ContainerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Container Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const ScanScreen(),
        '/history': (context) => const HistoryScreen(),
        '/registration': (context) => const RegistrationPage(),
      },
    );
  }
}