import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isUploading = false; 

  final _nameController = TextEditingController();
  final _locController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _imageUrl; 
  String _currentTier = 'free';
  String _currentSport = 'Futsal';
  int _reliabilityScore = 100; // Added: Track user reliability score state
  bool _isEmailVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _locController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.auth.refreshSession();
      final updatedUser = _supabase.auth.currentUser;
      final data = await _supabase.from('profiles').select().eq('id', updatedUser!.id).single();
      
      setState(() {
        _nameController.text = data['name'] ?? '';
        _locController.text = data['location'] ?? '';
        _emailController.text = updatedUser.email ?? '';
        _imageUrl = data['image_url']; 
        _currentTier = data['tier'] ?? 'free';
        _currentSport = data['sport'] ?? 'Futsal';
        _reliabilityScore = data['reliability_score'] ?? 100; // Added: Parse score from schema
        _isEmailVerified = updatedUser.emailConfirmedAt != null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      final fileName = '${user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
      } else {
        final file = File(image.path);
        await _supabase.storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase.from('profiles').update({'image_url': publicUrl}).eq('id', user.id);

      setState(() => _imageUrl = publicUrl);
      _showSnackBar("Profile picture updated!", isError: false);
    } catch (e) {
      debugPrint("Detailed Upload Error: $e");
      _showSnackBar("Upload failed: $e", isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _handlePasswordUpdate(String oldPass, String newPass) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: oldPass,
      );
      await _supabase.auth.updateUser(UserAttributes(password: newPass));
      if (mounted) _showSnackBar("Password updated securely!", isError: false);
    } on AuthException {
      _showSnackBar("Current password incorrect.", isError: true);
    } catch (e) {
      _showSnackBar("System Error: $e", isError: true);
    }
  }

  void _showChangePasswordSheet() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.all(Radius.circular(10))))),
            const SizedBox(height: 20),
            const Text("SECURITY VERIFICATION", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildEditField("Current Password", oldPassCtrl, Icons.lock_person, obscure: true),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10)),
            _buildEditField("New Password", newPassCtrl, Icons.lock_outline, obscure: true),
            const SizedBox(height: 12),
            _buildEditField("Confirm New Password", confirmCtrl, Icons.lock_reset, obscure: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  if (newPassCtrl.text == confirmCtrl.text && oldPassCtrl.text.isNotEmpty) {
                    _handlePasswordUpdate(oldPassCtrl.text, newPassCtrl.text);
                    Navigator.pop(context);
                  } else {
                    _showSnackBar("Passwords mismatch or empty fields.", isError: true);
                  }
                },
                child: const Text("CONFIRM CHANGES", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF39FF14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.sync_rounded, color: Colors.white54), onPressed: _fetchProfile),
          IconButton(icon: const Icon(Icons.check_circle, color: Color(0xFF39FF14)), onPressed: () async {
            await _supabase.from('profiles').update({
              'name': _nameController.text.trim(),
              'location': _locController.text.trim(),
            }).eq('id', _supabase.auth.currentUser!.id);
            _showSnackBar("Cloud Sync Complete", isError: false);
          }),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHero(),
                const SizedBox(height: 40),
                const Text("ACCOUNT SECURITY", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.verified_user_rounded,
                  title: "Identity Verification",
                  subtitle: _isEmailVerified ? "Verified Account" : "Action Required",
                  trailing: _isEmailVerified ? const Icon(Icons.verified, color: Color(0xFF39FF14)) : const Text("PENDING", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                _buildSettingTile(
                  icon: Icons.security_update_good_rounded,
                  title: "Password Manager",
                  subtitle: "Tap to change password",
                  onTap: _showChangePasswordSheet,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                ),
                const SizedBox(height: 32),
                const Text("ATHLETE BIO", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 12),
                _buildEditField("Full Name", _nameController, Icons.person_outline),
                const SizedBox(height: 12),
                _buildEditField("Location", _locController, Icons.location_on_outlined),
                const SizedBox(height: 32),
                _buildTierBanner(),
                const SizedBox(height: 50),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _supabase.auth.signOut();
                      if (!mounted) return;
                      navigator.pop();
                    },
                    child: const Text("LOGOUT SESSION", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _updateProfilePicture,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF39FF14),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: _imageUrl != null 
                        ? NetworkImage(_imageUrl!) 
                        : const AssetImage('assets/images/me.jpg') as ImageProvider,
                  ),
                ),
                if (_isUploading)
                  const CircularProgressIndicator(color: Colors.black),
                if (!_isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF39FF14), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameController.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(_currentSport.toUpperCase(), style: const TextStyle(color: Color(0xFF39FF14), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Added: Dynamic Reliability Score Badge
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      "RELIABILITY: $_reliabilityScore%",
                      style: TextStyle(
                        color: _reliabilityScore >= 80 ? const Color(0xFF39FF14) : Colors.amber, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, VoidCallback? onTap, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF39FF14)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: trailing,
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTierBanner() {
    bool isPremium = _currentTier == 'premium';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPremium ? const Color(0xFF39FF14) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(isPremium ? Icons.workspace_premium : Icons.stars, color: const Color(0xFF39FF14)),
          const SizedBox(width: 16),
          Expanded(child: Text(isPremium ? "PREMIUM STATUS" : "FREE ACCOUNT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
          Switch(
            value: isPremium,
            activeThumbColor: const Color(0xFF39FF14),
            onChanged: (val) async {
              final newTier = val ? 'premium' : 'free';
              await _supabase.from('profiles').update({'tier': newTier}).eq('id', _supabase.auth.currentUser!.id);
              setState(() => _currentTier = newTier);
            },
          )
        ],
      ),
    );
  }
}