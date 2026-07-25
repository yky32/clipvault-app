import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceDim;
    final card = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final onSurface =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      surface: card,
      onSurface: onSurface,
      error: AppColors.error,
      onError: Colors.white,
      surfaceContainerHighest: isDark
          ? AppColors.surfaceElevatedDark
          : const Color(0xFFE5E5EA),
    );

    final textTheme = _textTheme(onSurface, secondary, isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Satoshi',
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      dividerColor: isDark
          ? AppColors.separatorDark.withValues(alpha: 0.6)
          : AppColors.separator.withValues(alpha: 0.55),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: bg,
        barBackgroundColor: bg.withValues(alpha: 0.86),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primary,
          textStyle: textTheme.bodyLarge!,
          navTitleTextStyle: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
          navLargeTitleTextStyle: textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 34,
            letterSpacing: 0.37,
            height: 1.1,
          ),
          actionTextStyle: textTheme.bodyLarge!.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withValues(alpha: 0.94),
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: AppColors.primary, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.primary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.group),
        clipBehavior: Clip.antiAlias,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        extendedTextStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceCardDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Satoshi',
          color: secondary.withValues(alpha: isDark ? 0.35 : 0.3),
          fontWeight: FontWeight.w400,
          fontSize: 17,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Satoshi',
          color: secondary.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.success;
          return isDark
              ? const Color(0xFF39393D)
              : const Color(0xFFE9E9EB);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(
          fontFamily: 'Satoshi',
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDimDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheet),
        showDragHandle: true,
        dragHandleColor: isDark
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.18),
        dragHandleSize: const Size(36, 5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 13,
          height: 1.35,
          color: secondary.withValues(alpha: isDark ? 0.7 : 0.65),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
        iconColor: AppColors.primary,
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          color: onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: secondary.withValues(alpha: isDark ? 0.55 : 0.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? AppColors.separatorDark.withValues(alpha: 0.6)
            : AppColors.separator.withValues(alpha: 0.55),
        thickness: 0.5,
        space: 0.5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary, bool isDark) {
    TextStyle base(double size, FontWeight weight, {double? height, double? tracking}) {
      return TextStyle(
        fontFamily: 'Satoshi',
        fontSize: size,
        fontWeight: weight,
        height: height ?? 1.25,
        letterSpacing: tracking ?? -0.3,
        color: primary,
      );
    }

    return TextTheme(
      displayLarge: base(34, FontWeight.w700, height: 1.1, tracking: 0.37),
      displayMedium: base(28, FontWeight.w700, height: 1.15, tracking: 0.36),
      headlineMedium: base(22, FontWeight.w700, height: 1.2, tracking: 0.35),
      headlineSmall: base(20, FontWeight.w600, tracking: -0.4),
      titleLarge: base(20, FontWeight.w600, tracking: -0.4),
      titleMedium: base(17, FontWeight.w600, tracking: -0.4),
      titleSmall: base(15, FontWeight.w600, tracking: -0.2),
      bodyLarge: base(17, FontWeight.w400, height: 1.35, tracking: -0.4),
      bodyMedium: base(15, FontWeight.w400, height: 1.35, tracking: -0.2),
      bodySmall: base(13, FontWeight.w400, height: 1.3, tracking: -0.08).copyWith(
        color: secondary.withValues(alpha: isDark ? 0.6 : 0.55),
      ),
      labelLarge: base(15, FontWeight.w600, tracking: -0.2),
      labelMedium: base(13, FontWeight.w500, tracking: -0.08),
      labelSmall: base(11, FontWeight.w500, tracking: 0.06).copyWith(
        color: secondary.withValues(alpha: isDark ? 0.5 : 0.45),
      ),
    );
  }
}
