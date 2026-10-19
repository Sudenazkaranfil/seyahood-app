import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../widgets/error_view.dart';
import '../l10n/app_strings.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  static const String baseUrl = ApiConfig.baseUrl;

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _errorMessage = context.tr('verify.incompleteCodeError'));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': _code}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          final message = context.tr('verify.successMessage');
          Navigator.pushReplacementNamed(context, '/login');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(message)));
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = context.trAuthErrorCode(
            data['error'] as String?,
            fallbackKey: 'verify.invalidCodeError'));
      }
    } catch (e) {
      setState(() => _errorMessage = context.tr('verify.genericError'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('verify.resentMessage'))));
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36)),
            boxShadow: [BoxShadow(
                color: AppTheme.navDark.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 28, 28),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 14),
                Text(context.tr('verify.title'),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(context.tr('verify.subtitle'),
                    style: AppTheme.sansBody(
                        size: 13,
                        color: Colors.white.withOpacity(0.8))),
              ]),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.terracotta.withOpacity(0.3), width: 2),
                ),
                child: Icon(Icons.mark_email_unread_outlined,
                    color: AppTheme.terracotta, size: 38),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(widget.email, style: AppTheme.sansBody(
                    size: 13, weight: FontWeight.w700,
                    color: AppTheme.terracotta)),
              ),
              const SizedBox(height: 8),
              Text(context.tr('verify.sentTo'),
                  style: AppTheme.sansBody(
                      size: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => SizedBox(
                  width: 46, height: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AppTheme.sansBody(
                        size: 22, weight: FontWeight.w800),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppTheme.border, width: 1.5)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppTheme.border, width: 1.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppTheme.terracotta, width: 2)),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_code.length == 6) _verify();
                    },
                  ),
                )),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorCard(message: _errorMessage),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(context.tr('verify.verifyButton'), style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w800,
                      color: Colors.white)),
                ),
              ),

              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(context.tr('verify.noCode'),
                    style: AppTheme.sansBody(
                        size: 13, color: AppTheme.textSecondary)),
                TextButton(
                  onPressed: _resendCode,
                  child: Text(context.tr('verify.resend'), style: AppTheme.sansBody(
                      size: 13, weight: FontWeight.w800,
                      color: AppTheme.terracotta)),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}