import 'package:flutter/material.dart';
import 'package:qr_scanner/screens/home_screen.dart';
import 'package:qr_scanner/screens/scan_screen.dart';
import 'package:qr_scanner/screens/history_screen.dart';
import 'package:qr_scanner/screens/login_page.dart';
import 'package:qr_scanner/screens/registration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:qr_scanner/screens/report_screen.dart';
import 'package:qr_scanner/screens/Add_container_data.dart';
import 'package:path_provider/path_provider.dart'; // ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ADD THIS: Initialize path_provider
  try {
    await getApplicationDocumentsDirectory();
    print("Path provider initialized successfully");
  } catch (e) {
    print("Path provider initialization error: $e");
  }

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
        '/report': (context) => const ReportsScreen(),
        '/AddContainer': (context) => const AddContainerData(),
      },
    );
  }
}