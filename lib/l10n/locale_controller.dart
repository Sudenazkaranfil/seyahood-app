import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Uygulama genelinde aktif dili tutar. `main.dart`'taki `MaterialApp`
/// bunu dinleyip `locale` değiştiğinde yeniden çiziliyor; dil tercihi
/// cihazda kalıcı olarak saklanır.
class LocaleController {
  static final ValueNotifier<Locale> notifier =
      ValueNotifier(const Locale('tr'));

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
