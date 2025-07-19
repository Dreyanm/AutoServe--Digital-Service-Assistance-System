import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'registered_users';

  // Registers a new user and stores it locally.
  Future<bool> registerUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);
    List<User> users = [];

    if (usersJson != null) {
      // Decode existing users from JSON string
      final List<dynamic> decodedUsers = json.decode(usersJson);
      users = decodedUsers.map((json) => User.fromJson(json)).toList();
    }

    // Check if user with this email already exists
    if (users.any((u) => u.email == user.email)) {
      return false; // User already exists
    }

    // Add new user
    users.add(user);
    // Encode the updated list of users to JSON string and save
    await prefs.setString(_usersKey, json.encode(users.map((u) => u.toJson()).toList()));
    return true;
  }

  // Authenticates a user based on email and password.
  Future<User?> loginUser(String email, String password) async {
    // Built-in staff and admin accounts
    final List<User> builtInAccounts = [
      User(
        fullName: 'Resorts Staff',
        email: 'staff@resort.com',
        password: 'staff123',
        role: 'staff',
      ),
      User(
        fullName: 'Administrator',
        email: 'admin@resort.com',
        password: 'admin123',
        role: 'admin',
      ),
    ];

    // Check built-in accounts first
    try {
      final builtInUser = builtInAccounts.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      return builtInUser;
    } catch (e) {
      // Not a built-in account, check registered users
    }

    // Check registered customer accounts
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);

    if (usersJson != null) {
      final List<dynamic> decodedUsers = json.decode(usersJson);
      final List<User> users = decodedUsers.map((json) => User.fromJson(json)).toList();

      // Find user by email and password
      try {
        return users.firstWhere(
          (user) => user.email == email && user.password == password,
        );
      } catch (e) {
        return null; // User not found or incorrect credentials
      }
    }
    return null; // No users registered
  }

  // Get built-in accounts for display purposes (credentials only)
  List<Map<String, String>> getBuiltInAccounts() {
    return [
      {
        'title': 'Staff Login',
        'subtitle': 'Customer Service & Resort Management',
        'email': 'staff@resort.com',
        'password': 'staff123',
        'role': 'staff',
      },
      {
        'title': 'Admin Login',
        'subtitle': 'Administrator Access',
        'email': 'admin@resort.com',
        'password': 'admin123',
        'role': 'admin',
      },
    ];
  }
}
