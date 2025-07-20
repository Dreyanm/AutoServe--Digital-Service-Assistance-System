import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/resort_information_screen.dart';
import 'screens/service_request_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/admin_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoServe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming 'Inter' font is available or default
      ),
      home: const SignInScreen(),
      routes: {
        '/signIn': (context) => const SignInScreen(),
        '/signUp': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/resortInfo': (context) => const ResortInformationScreen(),
        '/serviceRequest': (context) => const ServiceRequestScreen(),
        '/adminPanel': (context) => const AdminPanelScreen(),
        '/adminProfile': (context) => const AdminProfileScreen(),
      },
    );
  }
}
