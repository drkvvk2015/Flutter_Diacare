/// Theme Management Provider
/// 
/// Provides dynamic theming capabilities including light/dark modes,
/// custom color schemes, and Material Design 3 support.
/// 
/// Features:
/// - Dynamic color scheme generation
/// - System color adaptation
/// - Material Design 3 toggle
/// - Glassmorphic card styling
/// - Customizable seed colors
import 'package:flutter/material.dart';

/// Theme management provider for dynamic theming
/// 
/// Handles theme state and generates complete ThemeData configurations
/// for both light and dark modes with customizable color schemes.
class ThemeProvider extends ChangeNotifier {
  // Theme configuration properties
  Color _seedColor = const Color(0xFF43CEA2);
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterial3 = true;
  bool _useSystemColors = true;

  // Public getters for theme properties
  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;
  bool get useMaterial3 => _useMaterial3;
  bool get useSystemColors => _useSystemColors;

  /// Generate light theme with optional dynamic color scheme
  /// 
  /// Args:
  ///   dynamicColorScheme: Optional system-provided color scheme
  /// 
  /// Returns:
  ///   ThemeData configured for light mode with glassmorphic styling
  ThemeData getLightTheme({ColorScheme? dynamicColorScheme}) {
    final ColorScheme lightScheme =
        _useSystemColors && dynamicColorScheme != null
        ? dynamicColorScheme
        : ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          );

    return ThemeData(
      useMaterial3: _useMaterial3,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: lightScheme.surface,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        actionsIconTheme: IconThemeData(color: lightScheme.primary),
        toolbarTextStyle: TextStyle(color: lightScheme.primary),
      ),

      // Card theme with glassmorphic style
      cardTheme: CardThemeData(
        elevation: 10,
        color: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),

      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: lightScheme.primary, width: 2),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightScheme.surface,
        indicatorColor: lightScheme.primaryContainer,
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: lightScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            );
          }
          return TextStyle(color: lightScheme.onSurface);
        }),
      ),

      // Page transition theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),

      // Interaction effects
      splashColor: lightScheme.primary.withValues(alpha: 0.1),
      highlightColor: lightScheme.primary.withValues(alpha: 0.05),

      // Additional component themes
      chipTheme: ChipThemeData(
        backgroundColor: lightScheme.surface,
        selectedColor: lightScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightScheme.primaryContainer,
        foregroundColor: lightScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Generate dark theme
  ThemeData getDarkTheme({ColorScheme? dynamicColorScheme}) {
    final ColorScheme darkScheme =
        _useSystemColors && dynamicColorScheme != null
        ? dynamicColorScheme
        : ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          );

    return ThemeData(
      useMaterial3: _useMaterial3,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: darkScheme.surface,

      // Dark theme specific customizations
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 10,
        color: darkScheme.surface.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: darkScheme.surface.withValues(alpha: 0.8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  /// Change seed color
  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  /// Change theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggle Material 3 design
  void setUseMaterial3(bool useMaterial3) {
    _useMaterial3 = useMaterial3;
    notifyListeners();
  }

  /// Toggle system colors
  void setUseSystemColors(bool useSystemColors) {
    _useSystemColors = useSystemColors;
    notifyListeners();
  }

  /// Get predefined theme colors
  static List<Color> get predefinedColors => [
    const Color(0xFF43CEA2), // Default green
    const Color(0xFF667eea), // Purple
    const Color(0xFFf093fb), // Pink
    const Color(0xFF4facfe), // Blue
    const Color(0xFF00f2fe), // Cyan
    const Color(0xFFa8edea), // Mint
    const Color(0xFFfed6e3), // Light pink
    const Color(0xFFffecd2), // Peach
    const Color(0xFFcfdef3), // Light blue
    const Color(0xFFe0c3fc), // Lavender
  ];

  /// Get gradient colors based on seed color
  List<Color> getGradientColors() {
    final hsl = HSLColor.fromColor(_seedColor);
    return [
      _seedColor,
      hsl.withHue((hsl.hue + 30) % 360).toColor(),
      hsl.withHue((hsl.hue + 60) % 360).toColor(),
    ];
  }

  /// Save theme preferences (implement with SharedPreferences if needed)
  Future<void> savePreferences() async {
    // TODO: Implement with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('seed_color', _seedColor.value);
    // await prefs.setInt('theme_mode', _themeMode.index);
    // await prefs.setBool('use_material3', _useMaterial3);
    // await prefs.setBool('use_system_colors', _useSystemColors);
  }

  /// Load theme preferences (implement with SharedPreferences if needed)
  Future<void> loadPreferences() async {
    // TODO: Implement with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // _seedColor = Color(prefs.getInt('seed_color') ?? _seedColor.value);
    // _themeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? _themeMode.index];
    // _useMaterial3 = prefs.getBool('use_material3') ?? _useMaterial3;
    // _useSystemColors = prefs.getBool('use_system_colors') ?? _useSystemColors;
    // notifyListeners();
  }
}
