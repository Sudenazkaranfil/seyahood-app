import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ad_config.dart';
import 'subscription_service.dart';

/// Sayfa kaydetme veya bir ajandayı bitirip çıkma gibi "iş bitti"
/// anlarında, her N olayda bir geçiş (interstitial) reklamı gösterir.
/// Free kullanıcılara özeldir, spam hissi vermemesi için sıklığı
/// [AdConfig] üzerinden sınırlanır ve bir sonraki gösterim için önceden
/// yüklenir.
class InterstitialAdService {
  InterstitialAdService._internal();
  static final InterstitialAdService instance =
      InterstitialAdService._internal();

  static const _saveCountKey = 'canvas_save_count';
  static const _journalViewCountKey = 'explore_journal_view_count';

  InterstitialAd? _ad;
  bool _isLoading = false;

  void preload() {
    if (_ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Bir sayfa başarıyla kaydedildiğinde çağrılır. Kullanıcı Free ise
  /// ve sayaç eşiğe ulaştıysa yüklü reklamı gösterir.
  Future<void> onPageSaved() =>
      _maybeShow(_saveCountKey, AdConfig.interstitialEveryNSaves);

  /// Kullanıcı Keşfet'te başkasının ajandasını bitirip çıktığında
  /// çağrılır. Kullanıcı Free ise ve sayaç eşiğe ulaştıysa yüklü
  /// reklamı gösterir.
  Future<void> onJournalViewed() => _maybeShow(
      _journalViewCountKey, AdConfig.interstitialEveryNJournalViews);

  Future<void> _maybeShow(String counterKey, int everyN) async {
    try {
      final status = await SubscriptionService.instance.getStatus();
      if (status.isPlus || status.isPro) return;
    } catch (e) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(counterKey) ?? 0) + 1;
    await prefs.setInt(counterKey, count);

    if (count % everyN != 0) return;
    if (_ad == null) {
      preload();
      return;
    }

    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );
    ad.show();
  }
}
