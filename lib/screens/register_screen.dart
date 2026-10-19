import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/error_view.dart';
import '../l10n/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = context.tr('register.emptyFieldsError'));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        final message = context.tr('register.successMessage');
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message)));
      }
    } catch (e) {
      setState(() => _errorMessage = context.trError(e));
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
              padding: const EdgeInsets.fromLTRB(16, 14, 28, 28),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 14),
                Text(context.tr('register.title'), style: GoogleFonts.playfairDisplay(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(context.tr('register.subtitle'),
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
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel(context.tr('register.usernameLabel')),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hint: context.tr('register.usernameHint'),
                prefixIcon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 16),
              _buildLabel(context.tr('register.emailLabel')),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: context.tr('register.emailHint'),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildLabel(context.tr('register.passwordLabel')),
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

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorCard(message: _errorMessage),
              ],

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                      : Text(context.tr('register.submitButton'), style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w800,
                      color: Colors.white)),
                ),
              ),

              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(context.tr('register.alreadyHaveAccount'),
                    style: AppTheme.sansBody(
                        size: 13, color: AppTheme.textSecondary)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(context.tr('register.loginLink'), style: AppTheme.sansBody(
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