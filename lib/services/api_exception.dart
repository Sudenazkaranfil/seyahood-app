/// Servis katmanının fırlattığı, UI'a gösterilmeden önce
/// `context.tr(messageKey)` ile lokalize edilmesi gereken hata.
/// Servis katmanı `BuildContext`'e bağımlı olmadan çalışsın diye
/// insan-okunur metin değil, bir çeviri anahtarı taşır.
class ApiException implements Exception {
  final String messageKey;
  const ApiException(this.messageKey);

  @override
  String toString() => messageKey;
}
