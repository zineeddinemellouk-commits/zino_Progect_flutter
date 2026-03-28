import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:test/pages/department_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final Map<String, Map<String, String>> _localCredentials = const {
    'Student': {
      'student@test.com': '123456',
    },
    'Teacher': {
      'teacher@test.com': '123456',
    },
    'Department': {
      'admin@department.com': 'admin123',
    },
  };

  String selectedRole = "Student";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _changeRole(String role) {
    if (selectedRole == role) return;
    
    double targetPosition;
    if (role == "Student") {
      targetPosition = 0;
    } else if (role == "Teacher") {
      targetPosition = 1;
    } else {
      targetPosition = 2;
    }
    
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: targetPosition,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward(from: 0);
    setState(() {
      selectedRole = role;
    });
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final roleCredentials = _localCredentials[selectedRole] ?? const {};
    final isValidLogin = roleCredentials[email] == password;

    if (isValidLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login as $selectedRole successful")),
      );

      if (selectedRole == "Department") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DepartmentDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$selectedRole dashboard coming soon!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          /// Background
          Positioned(
            top: -100,
            left: -100,
            child: _blurCircle(const Color(0xFFB4C5FF), 300),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: _blurCircle(const Color(0xFF6FFBBE), 400),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 420,
                child: _loginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: const SizedBox(),
      ),
    );
  }

  Widget _loginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 165, 162, 162).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Welcome back",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Please enter your credentials",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 20),

                /// ✅ Role Switcher with Animation
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E8EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Ensure minimum width to avoid negative constraints
                      double availableWidth = constraints.maxWidth > 0 ? constraints.maxWidth - 8 : 400 - 8;
                      double buttonWidth = availableWidth / 3;
                      
                      return Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_slideAnimation.value * buttonWidth, 0),
                                child: Container(
                                  width: buttonWidth,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            children: [
                              _roleButton("Student"),
                              _roleButton("Teacher"),
                              _roleButton("Department"),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// Email
                _inputField(
                  controller: emailController,
                  hint: "Email",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                /// Password
                _inputField(
                  controller: passwordController,
                  hint: "Password",
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                /// ✅ BUTTON WORKING
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                   onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004AC6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Role Button with Animation
  Widget _roleButton(String role) {
    bool isActive = selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? const Color(0xFF004AC6)
                    : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEDEEF0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}