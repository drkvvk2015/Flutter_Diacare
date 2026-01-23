/// Splash Screen
/// 
/// Initial loading screen that checks onboarding status
/// and navigates to the appropriate screen.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/routes.dart';
import '../constants/ui_constants.dart';

/// Splash screen with loading animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initialize() async {
    // Simulate loading time
    await Future<void>.delayed(const Duration(seconds: 2));

    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

    if (mounted) {
      // Navigate to appropriate screen
      if (onboardingCompleted) {
        Navigator.of(context).pushReplacementNamed(Routes.roleSelection);
      } else {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: UIConstants.shadowLg,
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacingXl),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'DiaCare',
                  style: TextStyle(
                    fontSize: UIConstants.fontSize5Xl,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacingSm),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Your Health Companion',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeLg,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacing2Xl),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

