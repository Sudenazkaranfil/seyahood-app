import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/premium_screen.dart';
import '../theme/app_theme.dart';

/// Ajanda ya da sayfa limiti dolduğunda gösterilen, kullanıcıyı premium
/// ekranına yönlendiren bottom sheet.
Future<void> showLimitReachedSheet(
  BuildContext context, {
  required String limitType, // 'journal' | 'page'
}) {
  final isJournal = limitType == 'journal';
  final title = isJournal ? 'Ajanda limitine ulaştın' : 'Sayfa limitine ulaştın';
  final message = isJournal
      ? 'Ücretsiz planda en fazla 5 ajanda oluşturabilirsin. '
          'Plus ile 20, PRO ile sınırsız ajanda oluşturabilirsin.'
      : 'Ücretsiz planda bir ajandaya en fazla 15 sayfa ekleyebilirsin. '
          'Plus ile 40, PRO ile sınırsız sayfa ekleyebilirsin.';

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.terracottaLight,
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('👑', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: AppTheme.sansBody(size: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const PremiumScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Planları Gör',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ]),
    ),
  );
}
