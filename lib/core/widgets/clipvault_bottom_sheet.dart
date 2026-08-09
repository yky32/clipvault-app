import 'package:flutter/material.dart';

/// Shared modal bottom sheet launcher (Triftly-style).
/// Use for all user-input flows (create / edit / pickers).
abstract final class ClipVaultBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      // Let the sheet own home-indicator / keyboard insets via SheetScaffold.
      useSafeArea: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        // Cap against full screen only. SheetScaffold owns keyboard lift
        // (Padding bottom: viewInsets) so we don't subtract keyboard twice.
        final maxH = MediaQuery.sizeOf(ctx).height * 0.92;
        return _SheetKeyboardDismiss(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: child,
          ),
        );
      },
    );
  }
}

class _SheetKeyboardDismiss extends StatelessWidget {
  const _SheetKeyboardDismiss({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}
