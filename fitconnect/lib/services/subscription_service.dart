import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'profile_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final ProfileService _profileService = ProfileService();

  // Replace these with your actual RevenueCat API keys from https://app.revenuecat.com
  static const String _androidApiKey = 'test_xFrDwMsAqsGpVPqdmiyACtDqjGd';
  static const String _iosApiKey = 'test_xFrDwMsAqsGpVPqdmiyACtDqjGd';

  // Entitlement identifier configured in RevenueCat dashboard
  static const String entitlementPro = 'fitconnect_pro';

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  /// Initialize RevenueCat SDK
  Future<void> init({String? userId}) async {
    if (kIsWeb) {
      debugPrint("[SubscriptionService] Web platform: Using sandbox mock mode.");
      return;
    }

    try {
      String? apiKey;
      if (Platform.isAndroid) {
        apiKey = _androidApiKey;
      } else if (Platform.isIOS || Platform.isMacOS) {
        apiKey = _iosApiKey;
      }

      if (apiKey == null || apiKey.startsWith('goog_FitConnect') || apiKey.startsWith('appl_FitConnect')) {
        debugPrint("[SubscriptionService] Placeholder API key detected. Running in sandbox simulation mode.");
        _isConfigured = false;
        return;
      }

      final configuration = PurchasesConfiguration(apiKey);
      if (userId != null && userId.isNotEmpty) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint("[SubscriptionService] RevenueCat initialized successfully for user: $userId");

      // Check current entitlement status
      await checkEntitlements();
    } catch (e) {
      debugPrint("[SubscriptionService] Initialization failed: $e. Falling back to sandbox.");
      _isConfigured = false;
    }
  }

  /// Log in user to RevenueCat to link with Supabase ID
  Future<void> logIn(String userId) async {
    if (!_isConfigured) return;
    try {
      final logInResult = await Purchases.logIn(userId);
      await _syncEntitlementWithSupabase(logInResult.customerInfo);
    } catch (e) {
      debugPrint("[SubscriptionService] LogIn error: $e");
    }
  }

  /// Log out user from RevenueCat
  Future<void> logOut() async {
    if (!_isConfigured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint("[SubscriptionService] LogOut error: $e");
    }
  }

  /// Fetch active Offerings and Packages from RevenueCat
  Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("[SubscriptionService] Fetch offerings error: $e");
      return null;
    }
  }

  /// Purchase a RevenueCat package
  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) {
      // In sandbox mode without live keys, simulate instant upgrade
      await _profileService.updateTier('premium');
      return true;
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPro = customerInfo.entitlements.all[entitlementPro]?.isActive == true ||
                    customerInfo.entitlements.active.isNotEmpty;

      if (isPro) {
        await _profileService.updateTier('premium');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("[SubscriptionService] Purchase failed: $e");
      rethrow;
    }
  }

  /// Restore previous purchases (for iOS / Android re-installs)
  Future<bool> restorePurchases() async {
    if (!_isConfigured) {
      return true;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all[entitlementPro]?.isActive == true ||
                    customerInfo.entitlements.active.isNotEmpty;

      await _profileService.updateTier(isPro ? 'premium' : 'free');
      return isPro;
    } catch (e) {
      debugPrint("[SubscriptionService] Restore purchases failed: $e");
      rethrow;
    }
  }

  /// Check active customer entitlements and sync with Supabase
  Future<bool> checkEntitlements() async {
    if (!_isConfigured) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final proEntitlement = customerInfo.entitlements.all[entitlementPro];
      final bool isPro = proEntitlement != null && proEntitlement.isActive == true;

      if (isPro) {
        await _profileService.updateTier('premium');
      }
      return isPro;
    } catch (e) {
      debugPrint("[SubscriptionService] Check entitlements error: $e");
      return false;
    }
  }

  Future<void> _syncEntitlementWithSupabase(CustomerInfo customerInfo) async {
    final proEntitlement = customerInfo.entitlements.all[entitlementPro];
    final bool isPro = proEntitlement != null && proEntitlement.isActive == true;
    if (isPro) {
      await _profileService.updateTier('premium');
    }
  }
}
