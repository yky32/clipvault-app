import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Compact Apple-style “Copied” HUD (not a bottom snackbar).
class CopiedHud {
  CopiedHud._();

  static void show(BuildContext context, {required String message}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _CopiedHudView(
        message: message,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _CopiedHudView extends StatefulWidget {
  const _CopiedHudView({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_CopiedHudView> createState() => _CopiedHudViewState();
}

class _CopiedHudViewState extends State<_CopiedHudView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
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
    Future<void>.delayed(const Duration(milliseconds: 1100), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(_scale),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xE62C2C2E)
                      : const Color(0xE61C1C1E),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft press scale for list rows / cards.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
