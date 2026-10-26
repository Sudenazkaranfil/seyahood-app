import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showFeedback;

  const ErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.showFeedback = true,
  });

  void _sendFeedback(BuildContext context) async {
    final body = context.trf('errorView.feedbackEmailBody',
        {'message': message ?? context.tr('errorView.unknownError')});
    final uri = Uri(
      scheme: 'mailto',
      path: 'destek@seyahood.app',
      queryParameters: {
        'subject': context.tr('errorView.feedbackEmailSubject'),
        'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('errorView.noMailApp')),
            backgroundColor: AppTheme.navDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // İkon
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.terracottaLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.terracotta.withOpacity(0.3), width: 2),
            ),
            child: Icon(Icons.wifi_off_rounded,
                color: AppTheme.terracotta, size: 38),
          ),
          const SizedBox(height: 20),

          Text(context.tr('errorView.title'),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
              message ?? context.tr('errorView.defaultMessage'),
              textAlign: TextAlign.center,
              style: AppTheme.sansBody(
                  size: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          // Tekrar dene
          if (onRetry != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr('errorView.retryButton')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          if (onRetry != null && showFeedback)
            const SizedBox(height: 10),

          // Geri bildirim
          if (showFeedback)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendFeedback(context),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: Text(context.tr('errorView.sendFeedbackButton')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.terracotta,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.terracotta.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
class ErrorCard extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorCard({super.key, this.message, this.onRetry});

  void _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'destek@seyahood.app',
      queryParameters: {
        'subject': context.tr('errorView.feedbackEmailSubject'),
        'body': context.trf('errorView.feedbackEmailBodyShort',
            {'message': message ?? context.tr('errorView.unknownError')}),
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD5D5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD9534F), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
              message ?? context.tr('errorView.cardDefaultMessage'),
              style: const TextStyle(color: Color(0xFFD9534F),
                  fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (onRetry != null) ...[
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9534F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(context.tr('errorView.retryButton'),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => _sendFeedback(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBD5D5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 13, color: Color(0xFFD9534F)),
                const SizedBox(width: 4),
                Text(context.tr('errorView.feedbackLabel'),
                    style: const TextStyle(color: Color(0xFFD9534F),
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}