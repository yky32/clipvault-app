import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'settings_service.dart';

/// Soft App Store review prompt after real one-tap usage (P1).
///
/// Rules:
/// - Never on first launch / empty vault journey
/// - After ≥10 successful copies
/// - At most once (we set a flag when we *attempt* the system sheet)
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  final InAppReview _review = InAppReview.instance;

  /// Call after a successful copy. Safe to fire-and-forget.
  Future<void> recordSuccessfulCopyAndMaybePrompt() async {
    try {
      await SettingsService.instance.incrementSuccessfulCopyCount();
      if (!SettingsService.instance.shouldRequestInAppReview) return;

      final available = await _review.isAvailable();
      if (!available) return;

      // Mark before request so we don't spam if the sheet is rate-limited.
      await SettingsService.instance.setInAppReviewPrompted(true);
      await _review.requestReview();
    } catch (e, st) {
      debugPrint('[ClipVal Review] $e\n$st');
    }
  }
}
