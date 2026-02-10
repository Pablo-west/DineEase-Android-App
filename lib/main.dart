// import 'package:dine_ease/features/auth/auth_gate.dart';
import 'package:dine_ease/features/onboarding/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/state/app_state.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  assert(Firebase.apps.isNotEmpty);
  debugPrint(
    'Firebase initialized: ${Firebase.apps.map((e) => e.name).join(', ')}',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DineEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashPage(),
      builder: (context, child) {
        return AppScope(
          notifier: _state,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
