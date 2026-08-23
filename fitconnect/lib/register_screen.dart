import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'home_page.dart';
import 'services/subscription_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Image Selection State
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locController = TextEditingController();
  
  String _selectedSport = 'Futsal';
  String _selectedSkill = 'Intermediate';

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking profile image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting image: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

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

  // --- STEP VALIDATION & NAVIGATION LOGIC ---
  void _nextStep() {
    // 1. Mandatory Photo Check for Step 0
    if (_currentStep == 0 && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.photo_camera_front_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Please upload a profile photo first to register!")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Name Check for Step 1
    if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name to continue!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // 3. Email Check for Step 2
    final email = _emailController.text.trim();
    if (_currentStep == 2) {
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid email address (e.g. name@example.com)!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // 4. Password Check for Step 3
    if (_currentStep == 3 && _passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_currentStep < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  // --- SUPABASE REGISTRATION & PHOTO UPLOAD LOGIC ---
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      User? user;
      Session? session;

      // 1. Try Signing Up Auth User
      try {
        final AuthResponse res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': _nameController.text.trim()},
        );
        user = res.user;
        session = res.session;
      } on AuthException catch (authErr) {
        // If Auth account already exists in Supabase Auth, sign in to retrieve session & complete missing profile
        final msg = authErr.message.toLowerCase();
        if (msg.contains("already registered") || msg.contains("already exists") || msg.contains("user_already_exists")) {
          try {
            final signInRes = await Supabase.instance.client.auth.signInWithPassword(
              email: email,
              password: password,
            );
            user = signInRes.user;
            session = signInRes.session;
          } catch (signInErr) {
            throw Exception("This email is already registered. Please log in with your password.");
          }
        } else {
          rethrow;
        }
      }

      user ??= Supabase.instance.client.auth.currentUser;
      session ??= Supabase.instance.client.auth.currentSession;

      if (user != null) {
        String? imageUrl;

        // 2. Upload Profile Image to Supabase Storage bucket 'avatars'
        if (_selectedImage != null && _imageBytes != null) {
          try {
            final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await Supabase.instance.client.storage.from('avatars').uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );
            imageUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
          } catch (uploadError) {
            debugPrint("Storage avatar upload notice: $uploadError");
          }
        }

        // 3. Upsert Profile Record in Supabase
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'sport': _selectedSport,
          'skill_level': _selectedSkill,
          'location': _locController.text.trim().isEmpty ? 'Kuala Lumpur' : _locController.text.trim(),
          if (imageUrl != null) 'image_url': imageUrl,
          'tier': 'free',
          'reliability_score': 100,
        });

        // 4. Link with RevenueCat
        await SubscriptionService().logIn(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully! Welcome to FitConnect. ⚡"),
              backgroundColor: Color(0xFF39FF14),
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (session != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint("Registration Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          // Tinder Progress Bar (7 Total Steps)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 7,
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
                // STEP 0: MANDATORY PHOTO UPLOAD
                _tinderStep("Add your\nbest photo", _photoPickerWidget()),
                // STEP 1: NAME
                _tinderStep("My first\nname is", _inputField("Name", _nameController)),
                // STEP 2: EMAIL
                _tinderStep("My email\naddress is", _inputField("Email", _emailController)),
                // STEP 3: PASSWORD
                _tinderStep("My secret\npassword is", _inputField("Password", _passwordController, obscure: true)),
                // STEP 4: SPORT
                _tinderStep("My favorite\nsport is", _optionPicker(['Futsal', 'Football', 'Badminton', 'Tennis', 'Pickleball', 'Basketball', 'Volleyball', 'Running'], _selectedSport, (v) => setState(() => _selectedSport = v!))),
                // STEP 5: SKILL
                _tinderStep("My skill\nlevel is", _optionPicker(['Beginner', 'Intermediate', 'Competitive', 'Pro'], _selectedSkill, (v) => setState(() => _selectedSkill = v!))),
                // STEP 6: LOCATION
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
                    : Text(_currentStep == 6 ? "CREATE ACCOUNT" : "CONTINUE", 
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

  Widget _photoPickerWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              shape: BoxShape.circle,
              border: Border.all(
                color: _imageBytes != null ? const Color(0xFF39FF14) : Colors.white24,
                width: 3,
              ),
              boxShadow: _imageBytes != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: ClipOval(
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover, width: 150, height: 150)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: Color(0xFF39FF14), size: 40),
                        SizedBox(height: 8),
                        Text(
                          "TAP TO ADD",
                          style: TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF39FF14)),
                foregroundColor: const Color(0xFF39FF14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: const Text("CAMERA"),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, size: 16),
              label: const Text("GALLERY"),
            ),
          ],
        ),
        if (_imageBytes != null) ...[
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF39FF14), size: 16),
              SizedBox(width: 6),
              Text(
                "Photo selected! Ready to continue.",
                style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tinderStep(String title, Widget content) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
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