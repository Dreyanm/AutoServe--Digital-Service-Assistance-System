class User {
  final String fullName;
  final String email;
  final String password;
  final String role; // 'customer', 'staff', 'admin'

  User({
    required this.fullName, 
    required this.email, 
    required this.password,
    this.role = 'customer',
  });

  // Convert a User object into a Map.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  // Convert a Map into a User object.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      role: json['role'] ?? 'customer',
    );
  }
}
