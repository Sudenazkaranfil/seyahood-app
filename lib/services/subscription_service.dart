import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Backend'in JOURNAL_LIMIT_REACHED / PAGE_LIMIT_REACHED hatalarına karşılık
/// gelir; UI bunu yakalayıp genel bir hata yerine premium yönlendirmesi
/// gösterir.
class LimitReachedException implements Exception {
  final String limitType; // 'journal' | 'page'
  const LimitReachedException(this.limitType);
}

class SubscriptionStatus {
  final String plan;
  final bool isPlus;
  final bool isPro;
  final int journalLimit;
  final int pageLimit;

  const SubscriptionStatus({
    required this.plan,
    required this.isPlus,
    required this.isPro,
    required this.journalLimit,
    required this.pageLimit,
  });

  static const SubscriptionStatus free = SubscriptionStatus(
    plan: 'FREE',
    isPlus: false,
    isPro: false,
    journalLimit: 5,
    pageLimit: 15,
  );

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan']?.toString() ?? 'FREE',
      isPlus: json['isPlus'] ?? false,
      isPro: json['isPro'] ?? false,
      journalLimit: json['journalLimit'] ?? 5,
      pageLimit: json['pageLimit'] ?? 15,
    );
  }
}

/// Uygulama genelinde tek bir abonelik durumu kaynağı.
///
/// Home, profil, canvas editör gibi birden çok ekran aynı anda "kullanıcı
/// PRO mu" bilgisine ihtiyaç duyduğu için her ekranın kendi başına
/// `/subscription/status` çağırması yerine burada kısa süreli önbelleğe
/// alınır ve `ChangeNotifier` ile dinleyen widget'lar güncellenir.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._internal();
  static final SubscriptionService instance = SubscriptionService._internal();

  static const _cacheTtl = Duration(minutes: 5);

  SubscriptionStatus? _status;
  DateTime? _lastFetchedAt;

  /// Ağ isteği beklemeden anlık okunabilecek son bilinen durum.
  SubscriptionStatus get cachedStatus => _status ?? SubscriptionStatus.free;

  bool get _isCacheFresh =>
      _status != null &&
      _lastFetchedAt != null &&
      DateTime.now().difference(_lastFetchedAt!) < _cacheTtl;

  Future<SubscriptionStatus> getStatus({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh) return _status!;

    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/subscription/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      _status = SubscriptionStatus.fromJson(jsonDecode(response.body));
      _lastFetchedAt = DateTime.now();
      notifyListeners();
      return _status!;
    }
    throw Exception('Abonelik bilgisi alınamadı');
  }

  static const Map<String, String> _redeemErrorMessages = {
    'CODE_NOT_FOUND': 'Böyle bir kod bulunamadı',
    'CODE_INACTIVE': 'Bu kod artık aktif değil',
    'CODE_EXPIRED': 'Bu kodun süresi dolmuş',
    'CODE_LIMIT_REACHED': 'Bu kod kullanım limitine ulaşmış',
    'CODE_ALREADY_USED': 'Bu kodu daha önce kullandın',
    'CODE_REQUIRED': 'Lütfen bir kod gir',
  };

  /// Bir promosyon kodunu kullanıcı adına kullanır; başarılı olursa
  /// önbelleği hemen tazeler ki uygulamadaki tüm rozet/buton/kısıtlama
  /// UI'ları anında güncellensin.
  Future<SubscriptionStatus> redeemCode(String code) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/subscription/redeem-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode == 200) {
      return getStatus(forceRefresh: true);
    }
    final error = jsonDecode(response.body)['error'] as String?;
    throw Exception(_redeemErrorMessages[error] ?? 'Kod kullanılamadı');
  }

  Future<void> registerCustomer(String customerId) async {
    final token = await StorageService.getToken();
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/subscription/register-customer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'customerId': customerId}),
    );
  }

  /// Kullanıcı çıkış yaptığında önbelleği temizler, aksi halde bir
  /// sonraki kullanıcı kısa süreliğine öncekinin planını görebilir.
  void clear() {
    _status = null;
    _lastFetchedAt = null;
    notifyListeners();
  }
}
