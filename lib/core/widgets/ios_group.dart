import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// iOS Settings-style inset grouped section.
class IosGroup extends StatelessWidget {
  const IosGroup({
    required this.children,
    this.header,
    this.footer,
    this.inset = true,
    super.key,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  /// When false, skips outer horizontal inset (use inside sheets that
  /// already pad via [SheetScaffold]).
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset ? AppSpacing.lg : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                header!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                  color: AppColors.secondaryLabel(context),
                ),
              ),
            ),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: AppRadii.group,
            ),
            child: ClipRRect(
              borderRadius: AppRadii.group,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Divider(
                          height: 0.5,
                          thickness: 0.5,
                          color: AppColors.hairline(context),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.secondaryLabel(context),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class IosGroupTile extends StatelessWidget {
  const IosGroupTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.below,
    this.onTap,
    this.titleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Full-width control under the title row (segmented controls, etc.).
  final Widget? below;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleRow = Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            below != null ? 14 : 12,
          ),
          child: below == null
              ? titleRow
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: 12),
                    below!,
                  ],
                ),
        ),
      ),
    );
  }
}

/// Chevron used in iOS list rows.
class IosChevron extends StatelessWidget {
  const IosChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: AppColors.tertiaryLabel(context),
    );
  }
}
