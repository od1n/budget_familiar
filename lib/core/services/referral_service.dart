import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Servicio de referidos ────────────────────────────────────────────────────
//
// Tracks referrals in SharedPreferences (simple local approach).
// When a user joins via invite code, increment the inviter's referral count.
// After 3 referrals, set a flag that the subscription system can check.
//
// TODO: Move referral tracking server-side (Supabase) so the inviter's count
// increments automatically when someone joins their group, regardless of
// which device is active.

class ReferralService {
  static const _keyReferralCount = 'referral_count';
  static const _keyFreeMonthRedeemed = 'referral_free_month_redeemed';
  static const _requiredReferrals = 3;

  /// Increment the referral count by 1.
  Future<void> recordReferral() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyReferralCount) ?? 0;
    await prefs.setInt(_keyReferralCount, current + 1);
  }

  /// Returns the current referral count.
  Future<int> getReferralCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReferralCount) ?? 0;
  }

  /// Returns true if the user has >= 3 referrals and hasn't redeemed yet.
  Future<bool> hasEarnedFreeMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyReferralCount) ?? 0;
    final redeemed = prefs.getBool(_keyFreeMonthRedeemed) ?? false;
    return count >= _requiredReferrals && !redeemed;
  }

  /// Redeems the free month reward: resets the count and marks as redeemed.
  /// Returns true if successfully redeemed, false if not eligible.
  Future<bool> redeemFreeMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyReferralCount) ?? 0;
    if (count < _requiredReferrals) return false;

    await prefs.setInt(_keyReferralCount, 0);
    await prefs.setBool(_keyFreeMonthRedeemed, true);
    return true;
  }

  /// Required number of referrals for a free month.
  int get requiredReferrals => _requiredReferrals;
}

// ── Riverpod provider ──────────────────────────────────────────────────────────

final referralServiceProvider = Provider<ReferralService>((ref) {
  return ReferralService();
});

/// Provides the current referral count as an async value.
final referralCountProvider = FutureProvider<int>((ref) {
  return ref.read(referralServiceProvider).getReferralCount();
});

/// Provides whether the user has earned a free month.
final hasEarnedFreeMonthProvider = FutureProvider<bool>((ref) {
  return ref.read(referralServiceProvider).hasEarnedFreeMonth();
});
