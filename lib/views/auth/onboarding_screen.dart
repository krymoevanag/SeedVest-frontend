import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _data = [
    OnboardingData(
      title: 'Group Savings',
      description: 'Join a digital community of savers and grow your wealth together.',
      icon: Icons.groups_rounded,
    ),
    OnboardingData(
      title: 'M-Pesa Integration',
      description: 'Quick and secure contributions directly from your phone.',
      icon: Icons.phone_android_rounded,
    ),
    OnboardingData(
      title: 'Transparent Governance',
      description: 'Real-time tracking of contributions, penalties, and investments.',
      icon: Icons.gavel_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _data[index].icon,
                          size: 120,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _data[index].title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _data[index].description,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _data.length,
                      (index) => Container(
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.lightGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _currentPage == _data.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentPage == _data.length - 1) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
