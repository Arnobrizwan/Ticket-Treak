import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String email;
  
  const EditProfileScreen({
    super.key, 
    required this.userName,
    this.email = "arnob@example.com", // Default email if not provided
  });
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _isChangePasswordVisible = false;
  
  // Professional color palette (same as HomeDashboard)
  final backgroundColor = const Color(0xFFF5F7FA);
  final primaryColor = const Color(0xFF3F3D9A);
  final secondaryColor = const Color(0xFF6C63FF);
  final textColor = const Color(0xFF2D3142);
  final subtleGrey = const Color(0xFFEBEEF2);
  final darkGrey = const Color(0xFF8F96A3);
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: "+60 12 345 6789");
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                
                // Profile Picture
                _buildProfilePicture(),
                const SizedBox(height: 32),
                
                // Personal Information Section
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 16),
                
                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                _buildTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Password Section
                _buildSectionHeader("Password"),
                const SizedBox(height: 16),
                
                // Change Password Button
                _buildChangePasswordButton(),
                
                // Password Change Fields (conditionally visible)
                if (_isChangePasswordVisible) ...[
                  const SizedBox(height: 16),
                  
                  // Current Password Field
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: "Current Password",
                    isObscured: _obscureCurrentPassword,
                    toggleObscure: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // New Password Field
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: "New Password",
                    isObscured: _obscureNewPassword,
                    toggleObscure: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Save Button
                _buildSaveButton(),
                
                const SizedBox(height: 24),
                
                // Delete Account Button
                _buildDeleteAccountButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Avatar
        CircleAvatar(
          radius: 60,
          backgroundColor: primaryColor,
          child: Text(
            widget.userName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        // Edit button
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: subtleGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              // Implement image picker functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change profile picture')),
              );
            },
            child: Icon(
              Icons.camera_alt,
              color: primaryColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: subtleGrey, thickness: 1),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subtleGrey),
        ),
        prefixIcon: Icon(icon, color: primaryColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subtleGrey),
        ),
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility : Icons.visibility_off,
            color: darkGrey,
          ),
          onPressed: toggleObscure,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }
  
  Widget _buildChangePasswordButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isChangePasswordVisible = !_isChangePasswordVisible;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: subtleGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isChangePasswordVisible ? "Cancel Password Change" : "Change Password",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Icon(
              _isChangePasswordVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: darkGrey,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size.fromHeight(50),
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildDeleteAccountButton() {
    return TextButton.icon(
      onPressed: _showDeleteAccountDialog,
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
      ),
      label: const Text(
        'Delete Account',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically update the user's profile in your backend
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
    }
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: darkGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle account deletion
              Navigator.pop(context); // Close dialog
              
              // Show confirmation and navigate to login screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
              
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.login, 
                (route) => false
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}