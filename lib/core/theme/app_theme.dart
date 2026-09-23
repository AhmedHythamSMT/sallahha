import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — single source for color, type, spacing.
/// calm teal (trust/service) + coral/amber (priority/urgency).
class AppTokens {
  static const seed = Color(0xFF0E7C7B);
  static const seedDeep = Color(0xFF0A5E5D);
  static const urgent = Color(0xFFC2410C);
  static const success = Color(0xFF15803D);
  static const pending = Color(0xFFB45309);
  static const background = Color(0xFFF6F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF8A3D); // warm CTA coral
  static const accentDeep = Color(0xFFE06A1F);

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const minTarget = 48.0;
}

/// Signature gradients used across hero cards and CTA buttons.
class AppGradients {
  static const teal = LinearGradient(
    colors: [Color(0xFF12A5A3), AppTokens.seed, AppTokens.seedDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accent = LinearGradient(
    colors: [AppTokens.accent, AppTokens.accentDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const warmSheet = LinearGradient(
    colors: [Color(0xFFFFF6EF), Color(0xFFFFFBF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static List<BoxShadow> soft(ColorScheme scheme) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 16.r,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Premium design system — Tajawal type, soft rounded surfaces,
/// gradient CTAs. Mirrors the "hotel/shop/grocer" template polish
/// from the Best-Flutter-UI-Templates collection.
class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppTokens.seed,
          brightness: Brightness.light,
          surface: AppTokens.surface,
        ).copyWith(
          primary: AppTokens.seed,
          onPrimary: Colors.white,
          secondary: AppTokens.accent,
          onSecondary: Colors.white,
          surface: AppTokens.surface,
          onSurface: const Color(0xFF1B1F1E),
          error: const Color(0xFFB3261E),
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20.sp,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24.sp),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppTokens.seed,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(56.h),
              elevation: 0,
              shadowColor: Colors.transparent,
              textStyle: GoogleFonts.tajawal(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.surfaceContainerHighest;
                }
                return AppTokens.seed;
              }),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.accent,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(56.h),
          elevation: 0,
          textStyle: GoogleFonts.tajawal(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.seedDeep,
          minimumSize: Size.fromHeight(52.h),
          textStyle: GoogleFonts.tajawal(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.seedDeep,
          textStyle: GoogleFonts.tajawal(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppTokens.seed, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: AppTokens.seed.withValues(alpha: 0.12),
        side: BorderSide.none,
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTokens.seed.withValues(alpha: 0.14),
        elevation: 0,
        height: 64.h,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.tajawal(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppTokens.seedDeep,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.tajawal(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12.sp),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1.h,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.seed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF242927),
        contentTextStyle: GoogleFonts.tajawal(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        modalBackgroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTokens.seed,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        iconColor: AppTokens.seedDeep,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.tajawal(
          fontSize: 13.sp,
          color: scheme.onSurfaceVariant,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppTokens.seedDeep,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: AppTokens.seed,
        labelStyle: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 14.sp),
        dividerColor: Colors.transparent,
      ),
    );
  }
}
