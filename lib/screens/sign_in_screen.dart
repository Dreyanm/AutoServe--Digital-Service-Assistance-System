import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart'; // Import the dashboard screen
import 'staff_login_screen.dart'; // Import the staff login screen

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handles user login attempt
  void _signIn() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.red);
      return;
    }

    final user = await _authService.loginUser(email, password);

    if (user != null) {
      // Check if user is staff or admin - redirect them to use dedicated login
      if (user.role == 'staff' || user.role == 'admin') {
        _showSnackBar(
          'Please use the dedicated ${user.role} login card below for secure access.',
          Colors.orange,
        );
        return;
      }

      // Save user data to SharedPreferences for later use (customer only)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', user.fullName);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_role', user.role);
      
      String message = 'Login Successful!';
      _showSnackBar(message, Colors.green);
      
      // Navigate to regular customer dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      _showSnackBar('Invalid email or password.', Colors.red);
    }
  }

  // Displays a SnackBar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to light icons for better contrast with light background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for top status bar (like 9:41)
              const SizedBox(height: 20),
              // "Sign in" title
              Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your customer account',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Email or Username field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email or User Name',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 20),
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 10),
              // Forgot Password?
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password
                    _showSnackBar('Forgot password functionality not implemented.', Colors.blue);
                  },
                  child: Text(
                    'Forgot Password ?',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Or sign in With divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Or sign in With',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 30),
              // Social media icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialMediaButton(
                    imagePath: 'assets/google.png',
                    onPressed: () {
                      _showSnackBar('Google login not implemented.', Colors.blue);
                    },
                  ),
                  const SizedBox(width: 20),
                  _SocialMediaButton(
                    imagePath: 'assets/facebook.png',
                    onPressed: () {
                      _showSnackBar('Facebook login not implemented.', Colors.blue);
                    },
                  ),
                  const SizedBox(width: 20),
                  _SocialMediaButton(
                    imagePath: 'assets/twitter.png', // Using twitter icon for X
                    onPressed: () {
                      _showSnackBar('X (Twitter) login not implemented.', Colors.blue);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 50),
              
              // Important Notice for Staff/Admin
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Staff & Admin: Please use the dedicated login cards below. Do not use the customer login form above.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Staff & Admin Login Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.blue[600], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Staff & Admin Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Click on a card below to access the dedicated login page:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Staff Login Cards (Clickable)
                    ..._authService.getBuiltInAccounts().map((account) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          // Navigate to dedicated staff/admin login screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StaffLoginScreen(
                                accountType: account['role']!,
                                accountTitle: account['title']!,
                                accountSubtitle: account['subtitle']!,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: account['role'] == 'admin' ? Colors.red[200]! : Colors.blue[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: account['role'] == 'admin' 
                                      ? Colors.red[100] 
                                      : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  account['role'] == 'admin' 
                                      ? Icons.admin_panel_settings 
                                      : Icons.support_agent,
                                  color: account['role'] == 'admin' 
                                      ? Colors.red[600] 
                                      : Colors.blue[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account['title']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      account['subtitle']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: account['role'] == 'admin' 
                                            ? Colors.red[50] 
                                            : Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: account['role'] == 'admin' 
                                              ? Colors.red[200]! 
                                              : Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        'Click to login',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: account['role'] == 'admin' 
                                              ? Colors.red[700] 
                                              : Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: account['role'] == 'admin' 
                                    ? Colors.red[400] 
                                    : Colors.blue[400],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.login, color: Colors.blue[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on a card above to access the secure login page where you\'ll need to enter your credentials.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Don't have account? Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have account ? ",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signUp');
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for social media buttons
class _SocialMediaButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;

  const _SocialMediaButton({
    Key? key,
    required this.imagePath,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          imagePath,
          height: 30,
          width: 30,
        ),
      ),
    );
  }
}
