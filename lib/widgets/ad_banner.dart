import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import '../services/subscription_service.dart';

/// Free kullanıcılara gösterilen AdMob banner'ı. Plus/PRO kullanıcılarda
/// hiçbir şey render etmez (reklamsız deneyim özelliğiyle tutarlı).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFreePlan = true;

  @override
  void initState() {
    super.initState();
    _checkPlanAndLoadAd();
  }

  Future<void> _checkPlanAndLoadAd() async {
    try {
      final status = await SubscriptionService.instance.getStatus();
      final isFree = !status.isPlus && !status.isPro;
      if (!mounted) return;
      setState(() => _isFreePlan = isFree);
      if (isFree) _loadAd();
    } catch (e) {
      // Durum alınamazsa reklamsız bırakmak, hataen ücretli kullanıcıya
      // reklam göstermekten daha güvenli.
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFreePlan || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
