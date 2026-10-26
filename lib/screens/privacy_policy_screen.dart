import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        // Dark header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28)),
            boxShadow: [BoxShadow(
                color: AppTheme.navDark.withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('privacyPolicy.headerTitle'),
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.3)),
                      Text(context.tr('privacyPolicy.headerSubtitle'),
                          style: AppTheme.sansBody(
                              size: 11, weight: FontWeight.w600,
                              color: AppTheme.terracotta)),
                    ]),
              ]),
            ),
          ),
        ),

        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.terracottaLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.terracotta.withOpacity(0.35)),
                    ),
                    child: const Center(child: Icon(Icons.shield_outlined,
                        color: AppTheme.terracotta, size: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('privacyPolicy.bannerTitle'),
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 14, fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(context.tr('privacyPolicy.bannerDate'),
                            style: AppTheme.sansBody(
                                size: 11, weight: FontWeight.w600,
                                color: AppTheme.terracotta)),
                      ])),
                ]),
              ),
              const SizedBox(height: 20),
              _buildSection(context.tr('privacyPolicy.section1.title'),
                  context.tr('privacyPolicy.section1.content'),
                  icon: Icons.info_outline_rounded),
              _buildSection(context.tr('privacyPolicy.section2.title'),
                  context.tr('privacyPolicy.section2.content'),
                  icon: Icons.folder_open_outlined),
              _buildSection(context.tr('privacyPolicy.section3.title'),
                  context.tr('privacyPolicy.section3.content'),
                  icon: Icons.auto_stories_outlined),
              _buildSection(context.tr('privacyPolicy.section4.title'),
                  context.tr('privacyPolicy.section4.content'),
                  icon: Icons.cloud_done_outlined),
              _buildSection(context.tr('privacyPolicy.section5.title'),
                  context.tr('privacyPolicy.section5.content'),
                  icon: Icons.lock_outline_rounded),
              _buildSection(context.tr('privacyPolicy.section6.title'),
                  context.tr('privacyPolicy.section6.content'),
                  icon: Icons.hourglass_empty_rounded),
              _buildSection(context.tr('privacyPolicy.section7.title'),
                  context.tr('privacyPolicy.section7.content'),
                  icon: Icons.verified_user_outlined),
              _buildSection(context.tr('privacyPolicy.section8.title'),
                  context.tr('privacyPolicy.section8.content'),
                  icon: Icons.cookie_outlined),
              _buildSection(context.tr('privacyPolicy.section9.title'),
                  context.tr('privacyPolicy.section9.content'),
                  icon: Icons.family_restroom_outlined),
              _buildSection(context.tr('privacyPolicy.section10.title'),
                  context.tr('privacyPolicy.section10.content'),
                  icon: Icons.update_rounded),
              _buildSection(context.tr('privacyPolicy.section11.title'),
                  context.tr('privacyPolicy.section11.content'),
                  icon: Icons.mail_outline_rounded, isContact: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSection(String title, String content,
      {required IconData icon, bool isContact = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isContact ? AppTheme.terracottaLight : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isContact
                ? AppTheme.terracotta.withOpacity(0.4) : AppTheme.border,
            width: isContact ? 1.4 : 1.0),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppTheme.terracotta),
          const SizedBox(width: 8),
          Expanded(child: Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary))),
        ]),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(
            fontSize: 13.5,
            color: isContact
                ? const Color(0xFF523F31) : AppTheme.textSecondary,
            height: 1.6)),
      ]),
    );
  }
}