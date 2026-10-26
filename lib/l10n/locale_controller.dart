import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_strings.dart';

/// Uygulama genelinde aktif dili tutar. `main.dart`'taki `MaterialApp`
/// bunu dinleyip `locale` değiştiğinde yeniden çiziliyor; dil tercihi
/// cihazda kalıcı olarak saklanır.
class LocaleController {
  static final ValueNotifier<Locale> notifier =
      ValueNotifier(_deviceDefault());

  /// Kayıtlı bir tercih yoksa (ilk açılış), cihazın dili desteklenen
  /// dillerden biriyse onu kullan; değilse İngilizce'ye düş — global
  /// kullanıcılar için varsayılan olarak Türkçe göstermemek adına.
  static Locale _deviceDefault() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    final supported =
        AppStrings.supportedLocales.map((l) => l.languageCode);
    if (supported.contains(deviceCode)) return Locale(deviceCode);
    return const Locale('en');
  }

  static Future<void> load() async {
    final saved = await StorageService.getLanguageCode();
    if (saved != null) {
      notifier.value = Locale(saved);
    }
  }

  static Future<void> setLocale(Locale locale) async {
    notifier.value = locale;
    await StorageService.saveLanguageCode(locale.languageCode);
  }
}
