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
    final safePadding = MediaQuery.paddingOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    // When the keyboard is up, home-indicator inset is already consumed by
    // the keyboard — don't reserve it again (avoids a gap above the keys).
    final bottomSafe = keyboardOpen ? 0.0 : safePadding.bottom;
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

    // Footer sits flush on the keyboard when open — no SafeArea bottom, no
    // extra home-indicator padding that leaves empty corners above the keys.
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

    final sheetBody = Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      width: double.infinity,
      decoration: BoxDecoration(
        color: sheetColor,
        // Top corners only — square bottom so it meets the keyboard edge-to-edge.
        borderRadius: AppRadii.sheet,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
          final headerH = (showDragHandle ? 18.0 : 0) +
              (title != null && title!.isNotEmpty
                  ? (hasSubtitle ? 52.0 : 36.0)
                  : 0);
          final footerH = hasFooter
              ? 90.0 + (keyboardOpen ? 0.0 : bottomSafe)
              : (hugContent ? bottomSafe : 0);
          final bodyMax = (constraints.maxHeight - headerH - footerH)
              .clamp(0.0, constraints.maxHeight);

          final scrollBody = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: bodyMax),
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

          if (hugContent) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildHeader(),
                scrollBody,
                if (footerWidget != null) footerWidget,
              ],
            );
          }

          return Column(
            children: [
              buildHeader(),
              Expanded(child: scrollBody),
              if (footerWidget != null) footerWidget,
            ],
          );
        },
      ),
    );

    // Solid bridge under the sheet into the keyboard zone (same color as the
    // sheet). Avoids transparent Padding holes where the barrier peeks through
    // at the top-left / top-right of the keyboard.
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        sheetBody,
        if (keyboardOpen)
          ColoredBox(
            color: sheetColor,
            child: SizedBox(
              height: viewInsets.bottom,
              width: double.infinity,
            ),
          )
        else
          SizedBox(height: 0, width: double.infinity),
      ],
    );
  }
}
