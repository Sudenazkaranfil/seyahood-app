import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../widgets/error_view.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  int _step = 1;

  static const String baseUrl = ApiConfig.baseUrl;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'E-posta adresinizi girin');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      if (response.statusCode == 200) {
        setState(() => _step = 2);
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['error'] ?? 'Bir hata oluştu');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Bağlantı hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_code.length < 6) {
      setState(() => _errorMessage = '6 haneli kodu girin');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _code,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _step = 3);
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['error'] ?? 'Geçersiz kod');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Bağlantı hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalı');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _code,
          'newPassword': _newPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Şifreniz başarıyla güncellendi!')));
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['error'] ?? 'Bir hata oluştu');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Bağlantı hatası');
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
              padding: const EdgeInsets.fromLTRB(16, 12, 28, 28),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconButton(
                  onPressed: () {
                    if (_step > 1) {
                      setState(() { _step--; _errorMessage = null; });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: index < _step
                            ? AppTheme.terracotta
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                Text(
                    _step == 1 ? 'Şifreni sıfırla'
                        : _step == 2 ? 'Kodu gir' : 'Yeni şifre',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                    _step == 1 ? 'E-posta adresini gir, kod gönderelim'
                        : _step == 2
                        ? '${_emailController.text} adresine gönderdik'
                        : 'Yeni şifreni belirle',
                    style: AppTheme.sansBody(
                        size: 13, color: Colors.white.withOpacity(0.8))),
              ]),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _step == 1 ? _buildEmailStep()
                  : _step == 2 ? _buildCodeStep()
                  : _buildPasswordStep(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('E-posta adresi'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'ornek@mail.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          autofocus: true,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorCard(message: _errorMessage),
        ],
        const SizedBox(height: 24),
        _buildButton('Kod gönder', _isLoading ? null : _sendCode),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => SizedBox(
            width: 44, height: 54,
            child: TextField(
              controller: _codeControllers[index],
              focusNode: _codeFocusNodes[index],
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
                  _codeFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _codeFocusNodes[index - 1].requestFocus();
                }
                if (_code.length == 6) _verifyCode();
              },
            ),
          )),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorCard(message: _errorMessage),
        ],
        const SizedBox(height: 24),
        _buildButton('Doğrula', _isLoading ? null : _verifyCode),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _sendCode,
            child: Text('Kodu tekrar gönder', style: AppTheme.sansBody(
                size: 13, weight: FontWeight.w800,
                color: AppTheme.terracotta)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Yeni şifre'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _newPasswordController,
          hint: 'En az 6 karakter',
          obscure: _obscurePassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Şifre tekrar'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: 'Şifreni tekrar gir',
          obscure: _obscureConfirm,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorCard(message: _errorMessage),
        ],
        const SizedBox(height: 24),
        _buildButton(
            'Şifremi güncelle', _isLoading ? null : _resetPassword),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTheme.sansBody(
        size: 13, weight: FontWeight.w700,
        color: const Color(0xFF523F31)));
  }

  Widget _buildButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.navDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: onPressed == null
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : Text(label, style: AppTheme.sansBody(
            size: 15, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    bool autofocus = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      autofocus: autofocus,
      style: AppTheme.sansBody(size: 14, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansBody(size: 13, color: AppTheme.textMuted),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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