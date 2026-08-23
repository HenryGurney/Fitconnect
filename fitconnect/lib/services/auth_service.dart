import 'package:supabase_flutter/supabase_flutter.dart';

import 'subscription_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns current authenticated user or null
  User? get currentUser => _supabase.auth.currentUser;

  /// Returns current authenticated user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Returns active auth session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Authenticate with email & password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user != null) {
      await SubscriptionService().logIn(res.user!.id);
    }
    return res;
  }

  /// Register a new user account
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    if (res.user != null) {
      await SubscriptionService().logIn(res.user!.id);
    }
    return res;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await SubscriptionService().logOut();
    await _supabase.auth.signOut();
  }

  /// Refresh auth session safely
  Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  /// Update account password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
