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
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final bottomSafe = keyboardOpen ? 0.0 : viewPadding.bottom;
    final maxHeight =
        MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppColors.surfaceDimDark : AppColors.warmWhite;
    final hasFooter = footer != null;
    final hugContent = compactBody;

    final bodyPadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
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

    // Keyboard lift: pad the panel up, and paint the same color under that
    // padding so the barrier never peeks through beside the keyboard.
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (keyboardOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: viewInsets.bottom + 2,
            child: ColoredBox(color: sheetColor),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              // Prefer parent-imposed height (welcome SizedBox); else cap at 92%.
              final maxH = outerConstraints.hasBoundedHeight &&
                      outerConstraints.maxHeight.isFinite
                  ? outerConstraints.maxHeight
                  : maxHeight;

              final scroll = SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: hasFooter
                    ? bodyPadding
                    : bodyPadding.copyWith(
                        bottom: AppSpacing.lg + bottomSafe,
                      ),
                child: child,
              );

              return Material(
                color: sheetColor,
                borderRadius: AppRadii.sheet,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  // Hug forms: only as tall as content, but never past maxH.
                  // Tall forms (welcome): fill maxH with Expanded body.
                  height: hugContent ? null : maxH,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: Column(
                      mainAxisSize:
                          hugContent ? MainAxisSize.min : MainAxisSize.max,
                      children: [
                        buildHeader(),
                        if (hugContent)
                          ConstrainedBox(
                            // Leave room for header + footer inside maxH.
                            constraints: BoxConstraints(
                              maxHeight: (maxH - 160).clamp(120.0, maxH),
                            ),
                            child: scroll,
                          )
                        else
                          Expanded(child: scroll),
                        if (footerWidget != null) footerWidget,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
