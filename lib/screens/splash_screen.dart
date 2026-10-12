import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC46B4E).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _controller, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboarding_done') ?? false;
        final token = prefs.getString('auth_token');

        if (!onboardingDone) {
          Navigator.pushReplacementNamed(context, '/onboarding');
          return;
        }

        if (token == null || token.isEmpty) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (response.statusCode == 200) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF160E08),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(children: [
          // Arka plan gradyanı
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF321A10),
                    Color(0xFF22110A),
                    Color(0xFF140A06),
                  ],
                ),
              ),
            ),
          ),

          // Dot grid
          Positioned.fill(
              child: CustomPaint(painter: _SplashDotPainter())),

          // Sağ üst halo
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFC46B4E).withOpacity(0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Sol alt halo
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFE89874).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // İçerik
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFFD5C2).withOpacity(0.4),
                          width: 3.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 28, offset: const Offset(0, 12)),
                        BoxShadow(
                            color: const Color(0xFFC46B4E).withOpacity(0.35),
                            blurRadius: 36, spreadRadius: 4),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Başlık
                  const Text('Seyahood',
                      style: TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.6,
                          fontFamily: 'serif')),

                  const SizedBox(height: 10),

                  // Slogan
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFFFD5C2).withOpacity(0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome_rounded, size: 13,
                          color: const Color(0xFFFFD5C2).withOpacity(0.85)),
                      const SizedBox(width: 6),
                      const Text('senin yolculuğun, senin hikayen',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: Color(0xFFFFD5C2), letterSpacing: 0.2)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          Positioned(
            bottom: 56, left: 0, right: 0,
            child: Column(children: [
              SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFC46B4E)),
                  backgroundColor: Colors.white.withOpacity(0.06),
                ),
              ),
              const SizedBox(height: 14),
              Text('seyahat ajandan açılıyor...',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 0.3)),
            ]),
          ),
        ]),
      ),
    );
  }
}