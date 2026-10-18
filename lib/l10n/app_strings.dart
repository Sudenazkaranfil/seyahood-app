import 'package:flutter/material.dart';
import 'strings_tr.dart';
import 'strings_en.dart';

/// Basit, kod üretimi gerektirmeyen çeviri katmanı. Yeni bir dil eklemek
/// için tek yapılması gereken: bu klasöre bir `strings_xx.dart` dosyası
/// eklemek ve aşağıdaki `_all` map'ine kaydetmek — `flutter gen-l10n`
/// gibi bir araç çalıştırmaya gerek yok.
class AppStrings {
  static const Map<String, Map<String, String>> _all = {
    'tr': stringsTr,
    'en': stringsEn,
  };

  static const List<Locale> supportedLocales = [Locale('tr'), Locale('en')];

  static String of(BuildContext context, String key) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'tr';
    final map = _all[code] ?? stringsTr;
    return map[key] ?? stringsTr[key] ?? key;
  }

  static String format(
      BuildContext context, String key, Map<String, String> params) {
    var value = of(context, key);
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
    return value;
  }
}

extension AppStringsExtension on BuildContext {
  String tr(String key) => AppStrings.of(this, key);
  String trf(String key, Map<String, String> params) =>
      AppStrings.format(this, key, params);
}
