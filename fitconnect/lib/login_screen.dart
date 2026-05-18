import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'register_screen.dart';
import 'home_page.dart'; // Unified dashboard hub

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to capture user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state to handle button UI during authentication
  bool _isLoading = false;

  /// Handles the Supabase Authentication logic
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Authenticating with Supabase
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // Redirection to the unified main hub
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),

                // Your high-res custom monogram
                Image.asset(
                  'assets/images/fitconnect.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_soccer,
                    size: 100,
                    color: Color(0xFF39FF14),
                  ),
                ),

                const Text(
                  "FITCONNECT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Elevate your game.",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 60),

                // Glassmorphic Input Group
                _buildGlassCard(
                  Column(
                    children: [
                      _buildTinderInput("Email", _emailController, false, Icons.email_outlined),
                      const SizedBox(height: 25),
                      _buildTinderInput("Password", _passwordController, true, Icons.lock_outline),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Functional Login Button
                _buildLoginButton(),

                const SizedBox(height: 30),

                // Switch to Register
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: "New here? ",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "CREATE ACCOUNT",
                          style: TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTinderInput(String hint, TextEditingController ctrl, bool obscure, IconData icon) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color.fromRGBO(57, 255, 20, 0.6),
          size: 20,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: const Color.fromRGBO(255, 255, 255, 0.1)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF39FF14)),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF39FF14), Color(0xFF00FF87)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(57, 255, 20, 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text(
            "GET STARTED",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}