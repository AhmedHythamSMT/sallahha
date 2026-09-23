import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding state. `true` = already seen (skipped) the intro flow.
final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
      return OnboardingController();
    });

class OnboardingController extends StateNotifier<bool> {
  static const _key = 'onboarding_seen';
  OnboardingController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
