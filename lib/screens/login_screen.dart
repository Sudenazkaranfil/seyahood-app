import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/error_view.dart';
import '../l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = context.tr('login.emptyFieldsError'));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await StorageService.saveToken(result['token']);
      await StorageService.saveUsername(result['username']);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage =
          e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
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
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 3),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Seyahood', style: GoogleFonts.playfairDisplay(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(context.tr('common.tagline'),
                      style: AppTheme.sansBody(
                          size: 12, weight: FontWeight.w600,
                          color: const Color(0xFFFFD5C2))),
                ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel(context.tr('login.emailOrUsernameLabel')),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: context.tr('login.emailHint'),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 18),
              _buildLabel(context.tr('login.passwordLabel')),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                obscure: _obscurePassword,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(context.tr('login.forgotPassword'),
                      style: AppTheme.sansBody(
                          size: 13, weight: FontWeight.w700,
                          color: AppTheme.terracotta)),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                ErrorCard(message: _errorMessage),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                          color: Colors.white, strokeWidth: 2.2))
                      : Text(context.tr('login.loginButton'), style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w800,
                      color: Colors.white)),
                ),
              ),

              const SizedBox(height: 18),

              Row(children: [
                Expanded(child: Divider(
                    color: AppTheme.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(context.tr('login.or'), style: AppTheme.sansBody(
                      size: 12, weight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider(
                    color: AppTheme.border, thickness: 1)),
              ]),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(context.tr('login.createAccountButton'), style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTheme.sansBody(
        size: 13, weight: FontWeight.w700,
        color: const Color(0xFF523F31)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTheme.sansBody(size: 14, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansBody(size: 13, color: AppTheme.textMuted),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.terracotta, width: 2)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.terracotta, size: 20) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}