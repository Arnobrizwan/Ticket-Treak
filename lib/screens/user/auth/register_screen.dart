import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  double _opacity = 0;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool isFormValid() {
    return (_formKey.currentState?.validate() ?? false) && _termsAccepted;
  }

  void _submitForm() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (_termsAccepted && isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Image.network(
                          'https://cdn-icons-png.flaticon.com/512/201/201623.png',
                          height: 120,
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildValidatedField('Full Name'),
                        const SizedBox(height: 12),
                        _buildValidatedField('Email', isEmail: true),
                        const SizedBox(height: 12),
                        _buildValidatedField('Phone'),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          'Password',
                          _passwordController,
                          _obscurePassword,
                          () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          'Confirm Password',
                          _confirmController,
                          _obscureConfirm,
                          () => setState(() => _obscureConfirm = !_obscureConfirm),
                          confirm: true,
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          value: _termsAccepted,
                          onChanged: (value) =>
                              setState(() => _termsAccepted = value ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            "I accept terms and conditions",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: isFormValid() ? _submitForm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                          child: const Text("Already have an account? Sign In"),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField(String label, {bool isEmail = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isEmail && !value.contains('@')) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle, {
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 6) {
          return '$label must be at least 6 characters';
        }
        if (confirm && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}