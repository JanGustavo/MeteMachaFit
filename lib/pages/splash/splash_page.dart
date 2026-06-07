// lib/pages/splash/splash_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Ícone
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),

              const SizedBox(height: 28),

              // Título
              Text(
                'GYM\nTRACKER',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 52,
                      height: 1.05,
                      letterSpacing: -2,
                      color: AppColors.onBackground,
                    ),
              ),

              const SizedBox(height: 20),

              // Taglines
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tagline('Acompanhe treinos'),
                  _tagline('Registre cargas e séries'),
                  _tagline('Monitore sua evolução'),
                ],
              ),

              const Spacer(flex: 3),

              // START
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(fontSize: 18, letterSpacing: 3),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
