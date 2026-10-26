import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF180F0A),
      body: Column(children: [
        Expanded(
          flex: 5,
          child: Stack(children: [
            Positioned.fill(
                child: CustomPaint(painter: _OnboardingDotPainter())),
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            PageView(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _currentPage = index),
              children: [
                _buildIllustration1(),
                _buildIllustration2(),
                _buildIllustration3(),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 18,
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                ),
                child: Text(context.tr('onboarding.skip'),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        letterSpacing: 0.2)),
              ),
            ),
          ]),
        ),

        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(
                color: Color(0x33000000), blurRadius: 24,
                offset: Offset(0, -6))],
          ),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: index == _currentPage ? 32 : 8,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? AppTheme.terracotta
                      : AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Column(
                key: ValueKey(_currentPage),
                children: [
                  Text(
                    _currentPage == 0
                        ? context.tr('onboarding.title1')
                        : _currentPage == 1
                        ? context.tr('onboarding.title2')
                        : context.tr('onboarding.title3'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900,
                        color: Color(0xFF1C110A), letterSpacing: -0.5,
                        fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentPage == 0
                        ? context.tr('onboarding.desc1')
                        : _currentPage == 1
                        ? context.tr('onboarding.desc2')
                        : context.tr('onboarding.desc3'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF6B5848),
                        height: 1.55, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage < 2
                          ? context.tr('onboarding.continueButton')
                          : context.tr('onboarding.startButton'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          letterSpacing: 0.2),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPage < 2
                          ? Icons.arrow_forward_rounded
                          : Icons.flight_takeoff_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 22),
          ]),
        ),
      ]),
    );
  }

  Widget _buildIllustration1() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.35), width: 3),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('assets/images/logo.png',
                      fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Seyahood',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5,
                    fontFamily: 'serif')),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(context.tr('common.tagline'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFFFFD5C2))),
            ),
            const SizedBox(height: 28),
            // Scrapbook kart önizleme
            Container(
              width: 220, height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.terracotta.withOpacity(0.4),
                    width: 1.5),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 18, offset: const Offset(0, 10))],
              ),
              child: Stack(children: [
                Positioned(
                  top: -6, left: 80,
                  child: Container(
                    width: 60, height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  top: 18, left: 14,
                  child: Container(
                    width: 90, height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5030), Color(0xFFC4956A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(child: Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white, size: 24)),
                  ),
                ),
                Positioned(
                  top: 22, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(context.tr('onboarding.mockCity'),
                        style: const TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C110A))),
                  ),
                ),
                Positioned(
                  bottom: 14, left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(context.tr('onboarding.mockCaption'),
                        style: const TextStyle(fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const Positioned(
                    bottom: 12, right: 16,
                    child: Text('🌸', style: TextStyle(fontSize: 24))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration2() {
    return SafeArea(
      child: Center(
        child: Container(
          width: 230, height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF221610),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.terracotta.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: CustomPaint(painter: _MapIllustrationPainter()),
        ),
      ),
    );
  }

  Widget _buildIllustration3() {
    return SafeArea(
      child: Center(
        child: Container(
          width: 230, height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF221610),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.terracotta.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: CustomPaint(painter: _ExploreIllustrationPainter()),
        ),
      ),
    );
  }
}

class _OnboardingDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC46B4E).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEADBCE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center,
              width: size.width * 0.78, height: size.height * 0.74),
          const Radius.circular(18)),
      paint,
    );

    final roadPaint = Paint()
      ..color = const Color(0xFF8B5030)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(center.dx - 45, center.dy + 35);
    path1.quadraticBezierTo(
        center.dx - 10, center.dy, center.dx + 42, center.dy - 25);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path();
    path2.moveTo(center.dx - 35, center.dy - 35);
    path2.quadraticBezierTo(
        center.dx - 5, center.dy + 15, center.dx + 35, center.dy + 35);
    canvas.drawPath(path2, roadPaint);

    paint.color = const Color(0xFFC46B4E);
    canvas.drawCircle(
        Offset(center.dx + 16, center.dy - 28), 15, paint);
    paint.color = Colors.white;
    canvas.drawCircle(
        Offset(center.dx + 16, center.dy - 28), 6, paint);

    paint.color = const Color(0xFFC46B4E);
    final pinPath = Path();
    pinPath.moveTo(center.dx + 16, center.dy - 13);
    pinPath.lineTo(center.dx + 9, center.dy - 6);
    pinPath.lineTo(center.dx + 23, center.dy - 6);
    pinPath.close();
    canvas.drawPath(pinPath, paint);

    paint.color = const Color(0xFFC46B4E).withOpacity(0.5);
    canvas.drawCircle(
        Offset(center.dx - 30, center.dy + 22), 5, paint);
    canvas.drawCircle(
        Offset(center.dx + 32, center.dy + 18), 5, paint);
    canvas.drawCircle(
        Offset(center.dx - 12, center.dy - 36), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExploreIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEADBCE);
    canvas.drawCircle(center, size.width * 0.34, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, size.width * 0.28, paint);

    final linePaint = Paint()
      ..color = const Color(0xFFC46B4E).withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(center.dx, center.dy - size.width * 0.25),
        Offset(center.dx, center.dy + size.width * 0.25), linePaint);
    canvas.drawLine(
        Offset(center.dx - size.width * 0.25, center.dy),
        Offset(center.dx + size.width * 0.25, center.dy), linePaint);

    paint.color = const Color(0xFFC46B4E);
    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - size.width * 0.22);
    northPath.lineTo(center.dx - 8, center.dy);
    northPath.lineTo(center.dx + 8, center.dy);
    northPath.close();
    canvas.drawPath(northPath, paint);

    paint.color = const Color(0xFFD4C5B0);
    final southPath = Path();
    southPath.moveTo(center.dx, center.dy + size.width * 0.22);
    southPath.lineTo(center.dx - 8, center.dy);
    southPath.lineTo(center.dx + 8, center.dy);
    southPath.close();
    canvas.drawPath(southPath, paint);

    paint.color = const Color(0xFFC46B4E);
    canvas.drawCircle(center, 6, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, 3, paint);

    void drawMiniBook(Offset pos) {
      paint.color = const Color(0xFFC46B4E).withOpacity(0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: 18, height: 22),
            const Radius.circular(4)),
        paint,
      );
      canvas.drawLine(
          Offset(pos.dx - 5, pos.dy - 5),
          Offset(pos.dx + 5, pos.dy - 5),
          Paint()..color = Colors.white.withOpacity(0.9)..strokeWidth = 1.5);
      canvas.drawLine(
          Offset(pos.dx - 5, pos.dy),
          Offset(pos.dx + 5, pos.dy),
          Paint()..color = Colors.white.withOpacity(0.9)..strokeWidth = 1.5);
    }

    drawMiniBook(Offset(center.dx - 52, center.dy - 48));
    drawMiniBook(Offset(center.dx + 52, center.dy - 42));
    drawMiniBook(Offset(center.dx - 45, center.dy + 50));
    drawMiniBook(Offset(center.dx + 48, center.dy + 46));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}