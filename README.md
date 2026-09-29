# Seyahood — Mobile App

Flutter ile geliştirilmiş dijital seyahat ajandası uygulaması. Kullanıcılar gezilerini sayfa sayfa, scrapbook tarzında kaydedebilir, haritada görebilir ve keşfedebilir.

## Teknolojiler

- Flutter (Dart)
- REST API entegrasyonu (`http` paketi)
- OpenStreetMap + `flutter_map` (harita)
- Nominatim API (geocoding)
- `exif_reader` (fotoğraf EXIF/GPS okuma)
- `image_picker` (fotoğraf seçimi)
- `shared_preferences` (token saklama)
- `google_mobile_ads` (AdMob banner + geçiş reklamları)
- `share_plus` + `screenshot` (paylaşım kartı export)
- Custom canvas editör (drag-drop, çizim, emoji, konum, font seçimi)

## Özellikler

- Kullanıcı kayıt / giriş (JWT), e-posta doğrulama, şifre sıfırlama
- Ajanda oluşturma ve yönetimi (public/private)
- Canvas/scrapbook sayfa editörü
  - Fotoğraf ekleme ve sürükleme
  - Yazı kutusu (8 ücretsiz + 10 PRO font)
  - Emoji seçici (7 kategori, 100+ emoji)
  - Parmakla serbest çizim (renk ve boyut seçimi)
  - Konum etiketi (Nominatim geocoding ile arama)
  - **AI destekli konum tahmini** (PRO): fotoğraf eklenince önce EXIF GPS'e bakılır (ücretsiz), yoksa "Tahmin Et" ile Google Vision (ücretsiz, ünlü yerler) ve gerekirse Claude (genel tahmin) sırayla denenir
- Defter görünümü (PageView + thumbnail)
- Harita ekranı (kendi konumların + public konumlar)
- Keşfet ekranı (public ajandalar, popüler kullanıcılar, arama)
- Takip sistemi ve başkasının ajandasını kaydetme
- Profil düzenleme
- **Plus/PRO abonelik sistemi**: detaylı karşılaştırma ekranı, plan bazlı limitler (ajanda/sayfa sayısı, export kalitesi, fontlar, paylaşım şablonları), promosyon kodu ile hediye/test üyelik
- **Paylaşım kartı stüdyosu**: 6 şablon (3 ücretsiz + 3 PRO), filigran kaldırma (Plus/PRO), plana göre export kalitesi (1x/2x/3x)
- **AdMob reklamları**: ücretsiz kullanıcılara banner (ana sayfa, keşfet, harita, profil) ve geçiş reklamı (sayfa kaydetme, başkasının ajandasından çıkış) — Plus/PRO'da gizli

## Kurulum

### Gereksinimler
- Flutter 3.x
- Android Studio / VS Code
- Android emülatör veya fiziksel cihaz

### Adımlar

1. Repoyu klonla
```bash
git clone https://github.com/Sudenazkaranfil/seyahood-app.git
cd seyahood-app
```

2. Bağımlılıkları yükle
```bash
flutter pub get
```

3. Backend URL'ini güncelle
`lib/config/api_config.dart` dosyasındaki `baseUrl`'i kendi backend adresinle değiştir.

4. Uygulamayı çalıştır
```bash
flutter run
```

## Ekran Görüntüleri

_Yakında eklenecek_

## Backend

Bu uygulama [Seyahood Backend](https://github.com/Sudenazkaranfil/seyahood) ile çalışır.
