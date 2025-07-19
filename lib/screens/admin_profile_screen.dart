import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String? adminName;
  String? adminEmail;
  String? adminRole;
  bool _isEditing = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // Admin profile data
  String adminPhone = '+63 912 345 6789';
  String adminDepartment = 'System Administration';
  String adminEmployeeId = 'ADM001';
  DateTime adminJoinDate = DateTime(2020, 1, 15);
  String adminLocation = 'Main Office, Resort Headquarters';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminName = prefs.getString('user_name') ?? 'Administrator';
      adminEmail = prefs.getString('user_email') ?? 'admin@resort.com';
      adminRole = prefs.getString('user_role') ?? 'admin';
      
      // Initialize controllers
      _nameController.text = adminName!;
      _emailController.text = adminEmail!;
      _phoneController.text = adminPhone;
      _departmentController.text = adminDepartment;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    
    setState(() {
      adminName = _nameController.text;
      adminEmail = _emailController.text;
      adminPhone = _phoneController.text;
      adminDepartment = _departmentController.text;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentPasswordController = TextEditingController();
        final newPasswordController = TextEditingController();
        final confirmPasswordController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate and change password logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: const Text('Change Password', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signIn',
                  (route) => false,
                );
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header Card
            _buildProfileHeader(),
            const SizedBox(height: 20),
            
            // Personal Information
            _buildPersonalInfo(),
            const SizedBox(height: 20),
            
            // Security Settings
            _buildSecuritySettings(),
            const SizedBox(height: 20),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[600]!, Colors.red[800]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            adminName ?? 'Administrator',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            adminRole?.toUpperCase() ?? 'ADMIN',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Employee ID: $adminEmployeeId',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 16),
          _buildInfoField('Email Address', _emailController, Icons.email_outlined),
          const SizedBox(height: 16),
          _buildInfoField('Phone Number', _phoneController, Icons.phone_outlined),
          const SizedBox(height: 16),
          _buildInfoField('Department', _departmentController, Icons.business_outlined),
          const SizedBox(height: 16),
          _buildReadOnlyInfo('Join Date', '${adminJoinDate.day}/${adminJoinDate.month}/${adminJoinDate.year}', Icons.calendar_today),
          const SizedBox(height: 16),
          _buildReadOnlyInfo('Location', adminLocation, Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: _isEditing 
            ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Security Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.password, color: Colors.orange[600]),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.security, color: Colors.blue[600]),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Enable 2FA for extra security'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.green,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.history, color: Colors.purple[600]),
            title: const Text('Login History'),
            subtitle: const Text('View recent login activity'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to login history
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Export profile data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile data exported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: Icon(Icons.download, color: Colors.red[600]),
            label: Text('Export Profile Data', style: TextStyle(color: Colors.red[600])),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[600]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
