import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/widget_deep_link.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-screen “Copied” flash after Home Screen widget deep link.
///
/// Goal: user never sees vault chrome during the required brief host open.
/// Pasteboard write stays in AppDelegate / [WidgetDeepLink] (locked path).
class WidgetCopyFlashPage extends StatefulWidget {
  const WidgetCopyFlashPage({super.key});

  @override
  State<WidgetCopyFlashPage> createState() => _WidgetCopyFlashPageState();
}

class _WidgetCopyFlashPageState extends State<WidgetCopyFlashPage>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.clipval/widget');

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    unawaited(HapticFeedback.mediumImpact());
    // Native multi-write runs on open; request bounce once flash is on screen.
    unawaited(Future<void>.delayed(const Duration(milliseconds: 520), () async {
      try {
        await _channel.invokeMethod<void>('bounceIfWidgetCopy');
      } catch (_) {}
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = WidgetDeepLink.lastFlashTitle;
    final chars = WidgetDeepLink.lastFlashChars;
    final subtitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'ClipVal';
    final charsLabel = (chars != null && chars > 0) ? '$chars chars' : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Copied',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (charsLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          charsLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      Text(
                        'Returning…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
