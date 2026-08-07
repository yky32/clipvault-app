import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'swipe_to_confirm.dart';

/// Consistent modal bottom sheet chrome (Triftly-aligned):
/// drag handle, optional title, scroll body, optional pinned footer.
///
/// Form sheets use [SheetScaffold.swipeForm] — no close button; dismiss
/// by swiping the sheet down; confirm with [SwipeToConfirm].
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
    this.onClose,
    this.showCloseButton = false,
    this.showDragHandle = true,
    this.compactBody = true,
    /// iOS form sheets look best with a centered title under the grabber.
    this.centerTitle = true,
    super.key,
  });

  /// Form sheet with [SwipeToConfirm] pinned in the footer (Triftly pattern A).
  factory SheetScaffold.swipeForm({
    required Widget child,
    required String swipeLabel,
    required bool swipeEnabled,
    required VoidCallback onSwipeConfirmed,
    String? title,
    String? subtitle,
    Key? swipeKey,
    SwipeToConfirmStyle swipeStyle = SwipeToConfirmStyle.primary,
    bool compact = true,
    bool isSubmitting = false,
    bool centerTitle = true,
  }) {
    return SheetScaffold(
      title: title,
      subtitle: subtitle,
      showCloseButton: false,
      compactBody: compact,
      centerTitle: centerTitle,
      footer: SwipeToConfirm(
        key: swipeKey,
        label: swipeLabel,
        enabled: swipeEnabled && !isSubmitting,
        style: swipeStyle,
        onConfirmed: onSwipeConfirmed,
      ),
      child: IgnorePointer(
        ignoring: isSubmitting,
        child: Opacity(
          opacity: isSubmitting ? 0.55 : 1,
          child: child,
        ),
      ),
    );
  }

  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool showDragHandle;
  final bool compactBody;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    // viewPadding is stable even when useSafeArea: false on the modal.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    // Keyboard covers the home indicator — don't double-count it.
    final bottomSafe = keyboardOpen ? 0.0 : viewPadding.bottom;
    final maxHeight =
        MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppColors.surfaceDimDark : AppColors.warmWhite;
    final hasFooter = footer != null;
    final hugContent = compactBody;

    final bodyPadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      title != null && title!.isNotEmpty ? AppSpacing.md : AppSpacing.md,
      AppSpacing.lg,
      hugContent ? AppSpacing.sm : AppSpacing.lg,
    );

    final footerWidget = hasFooter
        ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: sheetColor,
              border: Border(
                top: BorderSide(color: AppColors.hairline(context)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              // Flush to keyboard when open; home indicator only when closed.
              keyboardOpen ? AppSpacing.md : AppSpacing.lg + bottomSafe,
            ),
            child: footer,
          )
        : null;

    Widget buildHeader() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                showDragHandle ? 10 : AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      textAlign:
                          centerTitle ? TextAlign.center : TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryLabel(context),
                            height: 1.3,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    final sheetPanel = Material(
      color: sheetColor,
      // Top corners only — square bottom meets keyboard / home bar cleanly.
      borderRadius: AppRadii.sheet,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasSubtitle =
              subtitle != null && subtitle!.trim().isNotEmpty;
          final headerH = (showDragHandle ? 18.0 : 0) +
              (title != null && title!.isNotEmpty
                  ? (hasSubtitle ? 52.0 : 36.0)
                  : 0);
          // Button (~52) + paddings + optional home indicator.
          final footerH = hasFooter
              ? (12 + 52 + (keyboardOpen ? 12.0 : 16.0 + bottomSafe) + 1)
              : (hugContent ? bottomSafe : 0.0);
          final bodyMax = (constraints.maxHeight - headerH - footerH)
              .clamp(0.0, double.infinity);

          final scrollBody = ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: bodyMax.isFinite ? bodyMax : maxHeight,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: hasFooter
                  ? bodyPadding
                  : bodyPadding.copyWith(
                      bottom: AppSpacing.lg + bottomSafe,
                    ),
              child: child,
            ),
          );

          // Prefer Expanded when parent gives a bounded height (welcome sheet).
          final expandBody = constraints.hasBoundedHeight &&
              constraints.maxHeight < double.infinity &&
              !hugContent;

          if (expandBody) {
            return Column(
              children: [
                buildHeader(),
                Expanded(child: scrollBody),
                if (footerWidget != null) footerWidget,
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHeader(),
              scrollBody,
              if (footerWidget != null) footerWidget,
            ],
          );
        },
      ),
    );

    // Lift above keyboard with padding, and paint the same sheet color behind
    // that lift so barrier never peeks through at keyboard corners.
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (keyboardOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: viewInsets.bottom + 2,
            child: ColoredBox(color: sheetColor),
          ),
        AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: sheetPanel,
          ),
        ),
      ],
    );
  }
}
