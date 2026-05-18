import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locController = TextEditingController();
  
  String _selectedSport = 'Futsal';
  String _selectedSkill = 'Intermediate';

  // --- GOOGLE LOCATION LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ));

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locController.text = "${place.locality}, ${place.administrativeArea}";
        });
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not detect location automatically.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NAVIGATION LOGIC ---
  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  // --- SUPABASE REGISTRATION LOGIC ---
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create Auth User
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;

      if (user != null) {
        // 2. Link Profile Data (Using upsert to prevent duplication errors)
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'sport': _selectedSport,
          'skill_level': _selectedSkill,
          'location': _locController.text.trim(),
          'image_url': 'assets/images/aiman.jpg', // Placeholder for now
          'reliability_score': 100,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome to FitConnect!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint("Final Register Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme like Tinder
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300), curve: Curves.ease),
            ) 
          : null,
      ),
      body: Column(
        children: [
          // Tinder Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.white10,
              color: const Color(0xFF39FF14),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _tinderStep("My first\nname is", _inputField("Name", _nameController)),
                _tinderStep("My email\naddress is", _inputField("Email", _emailController)),
                _tinderStep("My secret\npassword is", _inputField("Password", _passwordController, obscure: true)),
                _tinderStep("My favorite\nsport is", _optionPicker(['Futsal', 'Badminton', 'Tennis', 'Basketball'], _selectedSport, (v) => setState(() => _selectedSport = v!))),
                _tinderStep("My skill\nlevel is", _optionPicker(['Beginner', 'Intermediate', 'Competitive', 'Pro'], _selectedSkill, (v) => setState(() => _selectedSkill = v!))),
                _tinderStep("My home\nbase is", _locationField()),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: GestureDetector(
              onTap: _isLoading ? null : _nextStep,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF39FF14), Color(0xFF00FF87)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.4), 
                      blurRadius: 20, 
                      offset: const Offset(0, 10)
                    )
                  ]
                ),
                child: Center(
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_currentStep == 5 ? "CREATE ACCOUNT" : "CONTINUE", 
                        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _tinderStep(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24, width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF39FF14), width: 2)),
      ),
    );
  }

  Widget _locationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField("City, State", _locController),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _getCurrentLocation,
          icon: const Icon(Icons.my_location, color: Color(0xFF39FF14)),
          label: const Text("USE MY CURRENT LOCATION", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _optionPicker(List<String> options, String current, Function(String?) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        bool isSelected = opt == current;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isSelected ? const Color(0xFF39FF14) : Colors.white24, width: 2),
              color: isSelected ? const Color(0xFF39FF14).withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Text(opt, style: TextStyle(color: isSelected ? const Color(0xFF39FF14) : Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}