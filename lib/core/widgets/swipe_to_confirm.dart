import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Visual style for [SwipeToConfirm].
enum SwipeToConfirmStyle {
  /// Teal fill follows the thumb from the start (sign-in, create trip, …).
  primary,

  /// Red fill fades in after 50% drag — for sign-out and other destructive actions.
  destructive,
}

/// Modern swipe-to-confirm track — slide the thumb right to complete.
class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
    this.style = SwipeToConfirmStyle.primary,
    super.key,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  final SwipeToConfirmStyle style;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> with TickerProviderStateMixin {
  static const _trackHeight = 58.0;
  static const _thumbSize = 50.0;
  static const _inset = 4.0;
  static const _confirmThreshold = 0.82;
  static const _velocityThreshold = 720.0;

  late final AnimationController _snapController;
  late final AnimationController _hintController;

  double _dragOffset = 0;
  double _maxDrag = 0;
  bool _confirmed = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController.unbounded(vsync: this)
      ..addListener(_onSnapTick);

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  void _onSnapTick() {
    if (!_snapController.isAnimating) return;
    setState(() => _dragOffset = _snapController.value.clamp(0.0, _maxDrag));
  }

  @override
  void didUpdateWidget(SwipeToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _dragOffset > 0 && !_confirmed) {
      _reset(animate: true);
    }
    if (widget.enabled && !_isDragging && !_confirmed) {
      if (!_hintController.isAnimating) _hintController.repeat(reverse: true);
    } else if (_isDragging || _confirmed) {
      _hintController.stop();
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  double get _progress => _maxDrag <= 0 ? 0 : (_dragOffset / _maxDrag).clamp(0.0, 1.0);

  bool get _isDestructive => widget.style == SwipeToConfirmStyle.destructive;

  /// Destructive: hold neutral until 50%, then ease into full red.
  double get _destructiveColorBlend {
    if (!_isDestructive) return 1;
    if (_progress <= 0.5) return 0;
    final t = ((_progress - 0.5) / 0.5).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(t);
  }

  double get _fillColorBlend => _destructiveColorBlend;

  /// Softer reveal so the red wash eases in rather than popping.
  double get _fillRevealOpacity {
    if (!_isDestructive) return 1;
    return Curves.easeOutCubic.transform(_destructiveColorBlend);
  }

  Color _accentColor(double blend, bool isDark) {
    if (_isDestructive) {
      final neutral = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
      return Color.lerp(neutral, AppColors.error, blend) ?? AppColors.error;
    }
    return AppColors.primary;
  }

  Color _labelColor(bool isDark, double blend) {
    final neutral = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    if (!_isDestructive) {
      return _progress > 0.35
          ? Colors.white.withValues(alpha: 0.92)
          : neutral;
    }

    final restTint = Color.lerp(neutral, AppColors.error, isDark ? 0.34 : 0.28) ?? neutral;

    if (blend <= 0) return restTint;

    if (blend < 0.5) {
      final t = Curves.easeOutCubic.transform(blend / 0.5);
      final onTrackRed = Color.lerp(
        AppColors.error,
        isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
        isDark ? 0.35 : 0.2,
      )!;
      return Color.lerp(restTint, onTrackRed, t) ?? onTrackRed;
    }

    final t = Curves.easeInOutCubic.transform((blend - 0.5) / 0.5);
    final onFillWhite = Colors.white.withValues(alpha: isDark ? 0.96 : 0.94);
    final midRed = Color.lerp(
      AppColors.error,
      isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
      isDark ? 0.35 : 0.2,
    )!;
    return Color.lerp(midRed, onFillWhite, t) ?? onFillWhite;
  }

  double _labelFadeOpacity() {
    if (_isDestructive) {
      return (1 - _progress * 0.95).clamp(0.0, 1.0);
    }
    return (1 - _progress * 1.25).clamp(0.0, 1.0);
  }

  double _thumbGlowAlpha(double blend) {
    if (!widget.enabled) return 0.08;
    if (_isDestructive) {
      return 0.06 + blend * (0.12 + _progress * 0.2);
    }
    return 0.18 + _progress * 0.22;
  }

  List<Color> _fillGradientColors(bool isDark, double blend) {
    if (!widget.enabled) {
      return [
        AppColors.border.withValues(alpha: 0.5),
        AppColors.border.withValues(alpha: 0.7),
      ];
    }

    final accent = _accentColor(blend, isDark);
    final depth = Color.lerp(accent, const Color(0xFFB91C1C), blend * 0.4) ?? accent;
    final strength = _isDestructive ? (0.25 + blend * 0.75) : 1.0;

    return [
      accent.withValues(alpha: (isDark ? 0.42 : 0.32) * strength),
      depth.withValues(alpha: (isDark ? 0.62 : 0.52) * strength),
    ];
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled || _confirmed) return;
    _isDragging = true;
    _hintController.stop();
    _snapController.stop();
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _confirmed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
    });
    if (_progress >= _confirmThreshold) _complete();
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || _confirmed) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    if (_progress >= _confirmThreshold || velocity > _velocityThreshold) {
      _complete(velocity: velocity);
    } else {
      _reset(animate: true);
      if (widget.enabled) _hintController.repeat(reverse: true);
    }
  }

  void _onDragCancel() {
    if (!widget.enabled || _confirmed) return;
    _isDragging = false;
    _reset(animate: true);
    if (widget.enabled) _hintController.repeat(reverse: true);
  }

  void _complete({double velocity = 0}) {
    if (_confirmed) return;
    _confirmed = true;
    _isDragging = false;
    HapticFeedback.mediumImpact();
    setState(() => _dragOffset = _maxDrag);
    widget.onConfirmed();
    _runSnap(to: _maxDrag, velocity: velocity);
  }

  void _reset({required bool animate}) {
    if (!animate) {
      setState(() => _dragOffset = 0);
      return;
    }
    _runSnap(to: 0, velocity: 0);
  }

  Future<void> _runSnap({
    required double to,
    required double velocity,
    VoidCallback? onEnd,
  }) async {
    _snapController.stop();
    _snapController.value = _dragOffset;

    await _snapController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 520, damping: 38),
        _dragOffset,
        to,
        velocity,
      ),
    );

    if (!mounted) return;
    setState(() => _dragOffset = to);
    onEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - _thumbSize - (_inset * 2);
        final fillWidth = (_dragOffset + _thumbSize + _inset).clamp(_thumbSize, constraints.maxWidth);
        final labelOpacity = _labelFadeOpacity();
        final thumbScale = _isDragging ? 1.03 : 1.0;
        final fillBlend = _fillColorBlend;
        final fillReveal = _fillRevealOpacity;
        final accent = _accentColor(fillBlend, isDark);
        final labelColor = _labelColor(isDark, fillBlend);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          opacity: widget.enabled ? 1 : 0.38,
          child: SizedBox(
            height: _trackHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF3F2EF),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fillWidth,
                  child: Opacity(
                    opacity: fillReveal,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: _fillGradientColors(isDark, fillBlend),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: labelOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.25,
                                color: labelColor,
                              ),
                            ),
                            if (widget.enabled && !_confirmed && !_isDragging) ...[
                              const SizedBox(width: 6),
                              AnimatedBuilder(
                                animation: _hintController,
                                builder: (context, _) {
                                  return Opacity(
                                    opacity: 0.35 + (_hintController.value * 0.45),
                                    child: _ChevronPair(size: 16, color: accent),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _inset + _dragOffset,
                  top: _inset,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: widget.enabled ? _onDragStart : null,
                    onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
                    onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
                    onHorizontalDragCancel: widget.enabled ? _onDragCancel : null,
                    child: AnimatedScale(
                      scale: thumbScale,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFFAFAF9) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: _thumbGlowAlpha(fillBlend)),
                              blurRadius: 12 + (_progress * 8),
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _confirmed
                              ? Icon(
                                  Icons.check_rounded,
                                  key: const ValueKey('check'),
                                  color: accent,
                                  size: 26,
                                )
                              : _ChevronPair(
                                  key: const ValueKey('chevrons'),
                                  size: 22,
                                  color: widget.enabled ? accent : AppColors.textTertiary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChevronPair extends StatelessWidget {
  const _ChevronPair({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;

    return SizedBox(
      width: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Icon(Icons.chevron_right_rounded, size: size, color: c.withValues(alpha: 0.55)),
          ),
          Positioned(
            right: 0,
            child: Icon(Icons.chevron_right_rounded, size: size, color: c),
          ),
        ],
      ),
    );
  }
}
