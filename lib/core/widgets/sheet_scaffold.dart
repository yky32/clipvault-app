import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Consistent modal bottom sheet chrome (aligned with Triftly SheetScaffold):
/// drag handle, title, scroll body, optional pinned footer.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
    this.onClose,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.compactBody = true,
    super.key,
  });

  /// Form sheet with a primary action button pinned in the footer.
  factory SheetScaffold.form({
    required Widget child,
    required String title,
    String? subtitle,
    required String actionLabel,
    required bool actionEnabled,
    required VoidCallback onAction,
    bool isSubmitting = false,
    bool compact = true,
  }) {
    return SheetScaffold(
      title: title,
      subtitle: subtitle,
      showCloseButton: true,
      compactBody: compact,
      footer: _SheetPrimaryButton(
        label: actionLabel,
        enabled: actionEnabled && !isSubmitting,
        isSubmitting: isSubmitting,
        onPressed: onAction,
      ),
      child: child,
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

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFooter = footer != null;
    final hugContent = compactBody;

    final bodyPadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      title != null && title!.isNotEmpty ? AppSpacing.sm : AppSpacing.md,
      AppSpacing.lg,
      hugContent ? AppSpacing.sm : AppSpacing.lg,
    );

    final footerWidget = hasFooter
        ? SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.hairline(context)),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md + (hugContent ? 0 : 0),
              ),
              child: footer,
            ),
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
                showDragHandle ? AppSpacing.sm : AppSpacing.md,
                showCloseButton ? AppSpacing.sm : AppSpacing.lg,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              color: AppColors.secondaryLabel(context),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      onPressed: onClose ?? () => Navigator.pop(context),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 28,
                        color: AppColors.tertiaryLabel(context)
                            .withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDim,
          borderRadius: AppRadii.sheet,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerH = (showDragHandle ? 20.0 : 0) +
                (title != null && title!.isNotEmpty ? 56.0 : 0);
            final footerH = hasFooter
                ? 72.0 + safePadding.bottom
                : (hugContent ? safePadding.bottom : 0);
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
                        bottom: AppSpacing.lg + safePadding.bottom,
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
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isSubmitting = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CupertinoActivityIndicator(color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
