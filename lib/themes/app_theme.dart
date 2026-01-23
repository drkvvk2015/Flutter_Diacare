/// Application Theme Configuration
/// 
/// Provides centralized theme definitions for the DiaCare application.
/// Implements both light and dark themes with consistent color schemes,
/// typography, and component styling.
/// 
/// Features:
/// - Material Design 3 support
/// - Google Fonts integration (Outfit font family)
/// - Cyber-themed color palette
/// - Consistent styling across all screens
library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme configuration class
/// 
/// Defines visual styling for both light and dark themes.
/// Uses cyber cyan as the primary color for a modern, tech-focused appearance.
class AppTheme {
  // Primary brand color - vibrant cyber cyan
  static const Color _primary = Color(0xFF00E5FF);
  
  // Light theme surface color - soft gray-blue
  static const Color _surface = Color(0xFFF5F7FA);

  /// Generates the light theme configuration
  /// 
  /// Returns:
  ///   ThemeData configured for light mode with cyber cyan accents
  static ThemeData lightTheme() {
    // Create color scheme from primary color with light brightness
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(seedColor: _primary)
            .copyWith(surface: _surface);
    
    return ThemeData(
      // Enable Material Design 3 components
      useMaterial3: true,
      // Apply custom color scheme
      colorScheme: colorScheme,
      // Light surface background
      scaffoldBackgroundColor: _surface,
      // Transparent app bar with no shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // Apply Outfit font from Google Fonts
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    );
  }

  /// Generates the dark theme configuration
  /// 
  /// Returns:
  ///   ThemeData configured for dark mode with deep blue-black backgrounds
  static ThemeData darkTheme() {
    // Create color scheme from primary color with dark brightness
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(seedColor: _primary, brightness: Brightness.dark)
            .copyWith(surface: const Color(0xFF0F2027));
    
    return ThemeData(
      // Enable Material Design 3 components
      useMaterial3: true,
      // Apply custom color scheme
      colorScheme: colorScheme,
      // Deep blue-black background for dark mode
      scaffoldBackgroundColor: const Color(0xFF0F2027),
      // Transparent app bar with no shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Apply Outfit font from Google Fonts
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    );
  }
}
