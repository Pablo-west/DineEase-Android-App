import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_gate.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_HowStep> _steps = const [
    _HowStep(
      title: 'Browse & pick',
      subtitle: 'Explore menus and choose what you love.',
      imagePath: 'assets/landing/browsePick.png',
    ),
    _HowStep(
      title: 'Customize',
      subtitle: 'Add extras, adjust spice, and set preferences.',
      imagePath: 'assets/landing/customize.png',
    ),
    _HowStep(
      title: 'We prepare',
      subtitle: 'Chefs start cooking as soon as you confirm.',
      imagePath: 'assets/landing/wePrepare.png',
    ),
    _HowStep(
      title: 'Out for delivery',
      subtitle: 'Deliveries reach your door or table number.',
      imagePath: 'assets/landing/outForDelivery.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('How it works', style: AppTextStyles.title),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _StepPage(step: step);
                },
              ),
            ),
            _pager(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0
                          ? null
                          : () {
                              _controller.previousPage(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut,
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _index == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pager() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _steps.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: i == _index ? 22 : 8,
            decoration: BoxDecoration(
              color: i == _index ? AppColors.primary : AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _StepPage extends StatelessWidget {
  final _HowStep step;

  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.asset(
                    step.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 90),
          Text(step.title, style: AppTextStyles.heading),
          const SizedBox(height: 20),
          Text(
            step.subtitle,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _HowStep {
  final String title;
  final String subtitle;
  final String imagePath;

  const _HowStep({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}
