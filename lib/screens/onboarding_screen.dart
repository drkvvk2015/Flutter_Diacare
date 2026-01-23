/// Onboarding Screen
/// 
/// Introduces new users to the DiaCare app features.
/// Shows key features and benefits before first use.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/routes.dart';
import '../constants/ui_constants.dart';

/// Onboarding flow for new users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to DiaCare',
      description:
          'Your comprehensive diabetes management companion. Track, monitor, and improve your health journey.',
      icon: Icons.favorite,
      color: Colors.red,
    ),
    OnboardingPage(
      title: 'Track Your Health',
      description:
          'Monitor blood glucose, blood pressure, weight, and other vital health metrics all in one place.',
      icon: Icons.health_and_safety,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Connect with Doctors',
      description:
          'Schedule appointments, have video consultations, and get expert medical advice anytime, anywhere.',
      icon: Icons.video_call,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Smart Analytics',
      description:
          'Get personalized insights and recommendations based on your health data and trends.',
      icon: Icons.analytics,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Stay on Track',
      description:
          'Receive medication reminders, appointment notifications, and health tips to keep you on your wellness journey.',
      icon: Icons.notifications_active,
      color: Colors.orange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip'),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: page.color,
            ),
          ),
          const SizedBox(height: UIConstants.spacingXl),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UIConstants.spacingMd),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingXl),
      child: Column(
        children: [
          _buildPageIndicator(),
          const SizedBox(height: UIConstants.spacingXl),
          SizedBox(
            width: double.infinity,
            height: UIConstants.buttonHeightLg,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1
                  ? _completeOnboarding
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusLg),
                ),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_currentPage > 0) ...[
            const SizedBox(height: UIConstants.spacingMd),
            TextButton(
              onPressed: _previousPage,
              child: const Text('Previous'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        _buildDot,
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXs),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(UIConstants.radiusFull),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);

    // Navigate to role selection
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.roleSelection);
    }
  }
}

/// Onboarding page model
class OnboardingPage {

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

