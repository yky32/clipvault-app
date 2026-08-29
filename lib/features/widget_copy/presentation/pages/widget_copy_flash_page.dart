import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/widget_deep_link.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-screen “Copied” flash after Home Screen widget deep link.
///
/// First tap from Home may bounce. Second widget tap leaves ClipVal in
/// foreground — user must be able to exit to vault (not trapped on Copied).
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

  bool _exited = false;

  @override
  void initState() {
    super.initState();
    WidgetDeepLink.flashTick.addListener(_onCopyTick);
    _controller.forward();
    unawaited(HapticFeedback.mediumImpact());
    unawaited(Future<void>.delayed(const Duration(milliseconds: 520), () async {
      try {
        await _channel.invokeMethod<void>('bounceIfWidgetCopy');
      } catch (_) {}
    }));
  }

  void _onCopyTick() {
    if (!mounted || _exited) return;
    setState(() {});
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  void dispose() {
    WidgetDeepLink.flashTick.removeListener(_onCopyTick);
    _controller.dispose();
    super.dispose();
  }

  void _exitToVault() {
    if (_exited || !mounted) return;
    _exited = true;
    WidgetDeepLink.consumeFlash();
    unawaited(() async {
      try {
        await _channel.invokeMethod<void>('cancelBounce');
      } catch (_) {}
    }());
    context.go(WidgetDeepLink.vaultLandingLocation);
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
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _exitToVault,
              child: SafeArea(
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
                            const SizedBox(height: 40),
                            TextButton(
                              onPressed: _exitToVault,
                              child: Text(
                                'Open vault',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
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
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Open vault',
                  onPressed: _exitToVault,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
