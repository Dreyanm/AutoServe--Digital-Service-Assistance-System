import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear any existing data for clean test
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  print('🧪 Testing Authentication System...\n');
  
  // Test 1: Create a user
  print('📝 Test 1: Creating a user...');
  await testCreateUser();
  
  // Test 2: Login with created user
  print('🔐 Test 2: Login with created user...');
  await testLogin();
  
  // Test 3: Check data persistence
  print('💾 Test 3: Check data persistence...');
  await testDataPersistence();
  
  print('\n✅ All tests completed!');
}

Future<void> testCreateUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userList = prefs.getStringList('users') ?? [];
  
  // Simulate signup
  final newUser = {
    'name': 'Test User',
    'email': 'test@example.com',
    'password': 'password123',
  };
  
  userList.add(jsonEncode(newUser));
  await prefs.setStringList('users', userList);
  
  print('   ✅ User created: ${newUser['email']}');
}

Future<void> testLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final userList = prefs.getStringList('users') ?? [];
  
  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  
  bool loginSuccess = false;
  
  for (String userJson in userList) {
    try {
      final userData = jsonDecode(userJson);
      final storedEmail = userData['email']?.toString() ?? '';
      final storedPassword = userData['password']?.toString() ?? '';
      
      if (storedEmail == testEmail && storedPassword == testPassword) {
        loginSuccess = true;
        break;
      }
    } catch (e) {
      continue;
    }
  }
  
  if (loginSuccess) {
    print('   ✅ Login successful');
  } else {
    print('   ❌ Login failed - this would show "Invalid credentials"');
  }
}

Future<void> testDataPersistence() async {
  final prefs = await SharedPreferences.getInstance();
  final userList = prefs.getStringList('users') ?? [];
  
  print('   📊 Stored users count: ${userList.length}');
  
  for (int i = 0; i < userList.length; i++) {
    try {
      final userData = jsonDecode(userList[i]);
      print('   👤 User ${i + 1}: ${userData['email']}');
    } catch (e) {
      print('   ⚠️  Corrupted user data at index $i');
    }
  }
}
