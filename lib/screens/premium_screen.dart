import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isYearly = false;
  bool _isLoading = true;
  String _currentPlan = 'FREE';
  final _promoCodeController = TextEditingController();
  bool _isRedeemingCode = false;

  static const List<_ComparisonFeature> _features = [
    _ComparisonFeature(
      icon: Icons.auto_stories_rounded,
      label: 'Ajanda',
      free: '5',
      plus: '20',
      pro: 'Sınırsız',
    ),
    _ComparisonFeature(
      icon: Icons.description_outlined,
      label: 'Sayfa / ajanda',
      free: '15',
      plus: '40',
      pro: 'Sınırsız',
    ),
    _ComparisonFeature(
      icon: Icons.explore_outlined,
      label: 'Gezgin rozeti',
      free: null,
      plus: '🧭 Gümüş',
      pro: '🧭 Altın',
    ),
    _ComparisonFeature(
      icon: Icons.image_outlined,
      label: 'Filigransız paylaşım',
      free: null,
      plus: '✓',
      pro: '✓',
    ),
    _ComparisonFeature(
      icon: Icons.high_quality_outlined,
      label: 'Export kalitesi',
      free: '1x',
      plus: '2x HD',
      pro: '3x 4K',
    ),
    _ComparisonFeature(
      icon: Icons.dashboard_customize_outlined,
      label: 'PRO şablonlar',
      free: null,
      plus: '1 şablon',
      pro: 'Tümü',
    ),
    _ComparisonFeature(
      icon: Icons.font_download_outlined,
      label: 'PRO canvas fontları',
      free: null,
      plus: null,
      pro: '✓',
    ),
    _ComparisonFeature(
      icon: Icons.travel_explore_rounded,
      label: 'AI konum tahmini',
      free: null,
      plus: null,
      pro: '✓',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await SubscriptionService.instance.getStatus();
      if (!mounted) return;
      setState(() {
        _currentPlan = status.plan;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isRedeemingCode = true);
    try {
      final status = await SubscriptionService.instance.redeemCode(code);
      if (!mounted) return;
      setState(() {
        _currentPlan = status.plan;
        _isRedeemingCode = false;
        _promoCodeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '🎉 Kod kullanıldı! Artık ${_planLabel(status.plan)} üyesisin.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRedeemingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _handlePurchase(String planLabel) {
    showModalBottomSheet(
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
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.terracottaLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('⏳', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(height: 16),
          Text('$planLabel yakında aktif oluyor',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
              'Satın alma altyapısı (RevenueCat) tamamlandığında bu plana '
              'buradan 7 gün ücretsiz deneme ile başlayabileceksin.',
              textAlign: TextAlign.center,
              style: AppTheme.sansBody(
                  size: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anladım'),
            ),
          ),
        ]),
      ),
    );
  }

  String _planLabel(String plan) {
    switch (plan) {
      case 'PLUS':
        return 'Plus';
      case 'PRO':
        return 'PRO';
      default:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBillingToggle(),
              const SizedBox(height: 8),
              _buildTrialBanner(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  _buildPlanCard(
                    planKey: 'PLUS',
                    title: 'Seyahood Plus',
                    ctaLabel: "Plus'a Geç",
                    emoji: '🧭',
                    color: AppTheme.sage,
                    monthlyPrice: 39.99,
                    yearlyPrice: 419.99,
                    highlight: false,
                    tagline: 'Daha fazla ajanda ve gümüş gezgin rozeti',
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    planKey: 'PRO',
                    title: 'Seyahood PRO',
                    ctaLabel: "PRO'ya Geç",
                    emoji: '👑',
                    color: AppTheme.terracotta,
                    monthlyPrice: 59.99,
                    yearlyPrice: 599.99,
                    highlight: true,
                    tagline: 'Sınırsız ajanda ve tüm premium özellikler',
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              _buildComparisonTable(),
              const SizedBox(height: 20),
              _buildPromoCodeSection(),
              const SizedBox(height: 16),
              _buildRestoreRow(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ]),
          ),
        ),
        Positioned(
          top: 12, left: 12,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.softShadow],
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.textPrimary, size: 20),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      decoration: const BoxDecoration(
        color: AppTheme.navDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 16),
        Text('Seyahood Premium',
            style: GoogleFonts.playfairDisplay(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Seyahatlerini sınırsız sayfada anlat',
            textAlign: TextAlign.center,
            style: AppTheme.sansBody(
                size: 13, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 14),
        if (!_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text('Mevcut plan: ${_planLabel(_currentPlan)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85))),
          ),
      ]),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.terracottaLight,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(children: [
        Expanded(child: _billingOption('Aylık', !_isYearly, false)),
        Expanded(child: _billingOption('Yıllık', _isYearly, true)),
      ]),
    );
  }

  Widget _billingOption(String label, bool selected, bool isYearlyValue) {
    return GestureDetector(
      onTap: () => setState(() => _isYearly = isYearlyValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navDark : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildTrialBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.card_giftcard_rounded,
            size: 14, color: AppTheme.sage),
        const SizedBox(width: 6),
        Text('Her iki planda da 7 gün ücretsiz deneme',
            style: AppTheme.sansBody(
                size: 12, weight: FontWeight.w700, color: AppTheme.sage)),
      ]),
    );
  }

  Widget _buildPlanCard({
    required String planKey,
    required String title,
    required String ctaLabel,
    required String emoji,
    required Color color,
    required double monthlyPrice,
    required double yearlyPrice,
    required bool highlight,
    required String tagline,
  }) {
    final price = _isYearly ? yearlyPrice : monthlyPrice;
    final period = _isYearly ? '/yıl' : '/ay';
    final isCurrent = _currentPlan == planKey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: highlight ? color : AppTheme.border,
            width: highlight ? 2 : 1),
        boxShadow: [highlight ? AppTheme.cardShadow : AppTheme.softShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(title,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  if (highlight) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('ÖNERİLEN',
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(tagline,
                    style: AppTheme.sansBody(
                        size: 12, color: AppTheme.textSecondary)),
              ])),
        ]),
        const SizedBox(height: 16),
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₺${price.toStringAsFixed(2)}',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(width: 4),
              Text(period,
                  style: AppTheme.sansBody(
                      size: 13, color: AppTheme.textSecondary)),
              if (_isYearly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.sage.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '%${(100 - (yearlyPrice / (monthlyPrice * 12) * 100)).round()} indirim',
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w800, color: AppTheme.sage)),
                ),
              ],
            ]),
        const SizedBox(height: 4),
        Text('7 gün ücretsiz dene, istediğin zaman iptal et',
            style: AppTheme.sansBody(size: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isCurrent ? null : () => _handlePurchase(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrent ? AppTheme.border : color,
              foregroundColor: isCurrent ? AppTheme.textSecondary : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isCurrent ? 'Mevcut Planın' : ctaLabel,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Detaylı Karşılaştırma',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Text('Free, Plus ve PRO arasındaki farklar',
                style: AppTheme.sansBody(size: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Free',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary)))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('🧭 Plus',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: AppTheme.sage)))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('👑 PRO',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: AppTheme.terracotta)))),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.border),
            ..._features.map(_buildFeatureRow),
          ]),
        ),
        // Washi bant köşesi
        Positioned(
          top: -10, left: 28,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 64, height: 20,
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withOpacity(0.55),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 1),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildFeatureRow(_ComparisonFeature f) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.terracottaLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.icon, size: 13, color: AppTheme.terracottaDark),
              ),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(f.label,
                      style: AppTheme.sansBody(
                          size: 12, weight: FontWeight.w600))),
            ])),
        Expanded(
            flex: 2,
            child: Center(
                child: _buildFeatureValue(f.free, AppTheme.textMuted))),
        Expanded(
            flex: 2,
            child: Center(child: _buildFeatureValue(f.plus, AppTheme.sage))),
        Expanded(
            flex: 2,
            child: Center(
                child: _buildFeatureValue(f.pro, AppTheme.terracotta))),
      ]),
    );
  }

  Widget _buildFeatureValue(String? value, Color tierColor) {
    if (value == null) {
      return Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border, width: 1.4),
        ),
      );
    }
    if (value == '✓') {
      return Container(
        width: 18, height: 18,
        decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }
    return Text(value,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, color: tierColor));
  }

  Widget _buildPromoCodeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.redeem_rounded, size: 18, color: AppTheme.terracotta),
          const SizedBox(width: 8),
          Text('Promosyon Kodun mu Var?',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 4),
        Text('Hediye ya da kampanya kodunu gir, planın hemen aktifleşsin.',
            style: AppTheme.sansBody(size: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _promoCodeController,
              textCapitalization: TextCapitalization.characters,
              style: AppTheme.sansBody(size: 14, weight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Örn. SEYAHOOD2026',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.terracotta, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isRedeemingCode ? null : _redeemPromoCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isRedeemingCode
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Kullan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRestoreRow() {
    return Center(
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Satın almalar RevenueCat entegrasyonu ile geri yüklenebilecek')));
        },
        child: const Text('Satın Alımları Geri Yükle'),
      ),
    );
  }
}

class _ComparisonFeature {
  final IconData icon;
  final String label;
  final String? free;
  final String? plus;
  final String? pro;

  const _ComparisonFeature({
    required this.icon,
    required this.label,
    required this.free,
    required this.plus,
    required this.pro,
  });
}
