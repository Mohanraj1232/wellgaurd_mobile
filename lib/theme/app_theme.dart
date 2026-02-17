import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textWhite,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textWhite,
        secondaryContainer: AppColors.secondaryDark,
        surface: AppColors.bgCard,
        onSurface: AppColors.textMain,
        error: AppColors.accentDanger,
        onError: AppColors.textWhite,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.bgMain,
      
      // Text theme
      textTheme: AppTypography.textTheme,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleMedium,
        iconTheme: const IconThemeData(
          color: AppColors.textMain,
          size: AppSpacing.iconMD,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLG,
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shadowColor: AppColors.shadowPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLG),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          textStyle: AppTypography.buttonLarge,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLG),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          textStyle: AppTypography.buttonLarge.copyWith(color: AppColors.primary),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.buttonMedium.copyWith(color: AppColors.primary),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.accentDanger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 2),
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentDanger,
        foregroundColor: AppColors.textWhite,
        elevation: 8,
        highlightElevation: 12,
        shape: CircleBorder(),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXL,
        ),
        titleTextStyle: AppTypography.titleMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCard,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMain),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMD,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCard,
        labelStyle: AppTypography.labelMedium,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSM,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textMain,
        minVerticalPadding: AppSpacing.sm,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: AppSpacing.md,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSpacing.iconMD,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.bgHover,
        linearTrackColor: AppColors.bgHover,
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.bgHover,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.bgHover;
        }),
      ),
      
      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(color: AppColors.borderLight),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppColors.textMain),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        dragHandleColor: AppColors.textMuted,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
    );
  }
}
