import 'package:flutter/material.dart';
import 'package:sticker_widget/sticker_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/photo_service.dart';
import '../services/subscription_service.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/limit_reached_sheet.dart';
import 'premium_screen.dart';
import 'package:google_fonts/google_fonts.dart';

const Set<String> kFreeCanvasFonts = {
  'Plus Jakarta Sans', 'Playfair Display', 'Caveat', 'Dancing Script',
  'Roboto Mono', 'Lora', 'Josefin Sans', 'Raleway',
};

class _StickerItem {
  dynamic model;
  final String type;
  final String? content;
  _StickerItem({required this.model, required this.type, this.content});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> modelJson = {};
    if (model is TextModel) {
      modelJson = (model as TextModel).toJson();
    } else if (model is PictureModel) {
      modelJson = (model as PictureModel).toJson();
    }
    return {'type': type, 'content': content, 'model': modelJson};
  }
}

class _LocationItem {
  String name;
  double x;
  double y;
  double? lat;
  double? lng;
  Color color;
  double scale;
  double angle;
  final GlobalKey key = GlobalKey();

  _LocationItem({
    required this.name,
    this.x = 80,
    this.y = 200,
    this.lat,
    this.lng,
    this.color = const Color(0xFFC4956A),
    this.scale = 1.0,
    this.angle = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'x': x, 'y': y, 'lat': lat, 'lng': lng,
    'color': color.value, 'scale': scale, 'angle': angle,
  };

  factory _LocationItem.fromJson(Map<String, dynamic> json) => _LocationItem(
    name: json['name'] ?? '',
    x: (json['x'] as num? ?? 80).toDouble(),
    y: (json['y'] as num? ?? 200).toDouble(),
    lat: json['lat']?.toDouble(),
    lng: json['lng']?.toDouble(),
    color: json['color'] != null ? Color(json['color']) : const Color(0xFFC4956A),
    scale: (json['scale'] as num? ?? 1.0).toDouble(),
    angle: (json['angle'] as num? ?? 0.0).toDouble(),
  );
}

class DrawingPath {
  List<Offset> points;
  Color color;
  double strokeWidth;

  DrawingPath({required this.points, required this.color, required this.strokeWidth});

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'strokeWidth': strokeWidth,
  };

  factory DrawingPath.fromJson(Map<String, dynamic> json) => DrawingPath(
    points: (json['points'] as List).map((p) =>
        Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(),
    color: Color(json['color'] as int),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}

class CanvasEditorScreen extends StatefulWidget {
  final int journalId;
  final Entry? entry;
  const CanvasEditorScreen({super.key, required this.journalId, this.entry});

  @override
  State<CanvasEditorScreen> createState() => _CanvasEditorScreenState();
}

class _CanvasEditorScreenState extends State<CanvasEditorScreen> {
  final List<_StickerItem> _stickers = [];
  final List<_LocationItem> _locations = [];
  List<DrawingPath> _drawingPaths = [];
  DrawingPath? _currentPath;
  bool _isDrawingMode = false;
  Color _drawingColor = const Color(0xFF2C2420);
  double _drawingSize = 4.0;
  Color _backgroundColor = const Color(0xFFFAF7F2);
  bool _isLoading = false;
  int? _selectedLocationIndex;
  _StickerItem? _clipboard;
  final List<Map<String, dynamic>> _legacyElements = [];
  int? _selectedStickerIndex;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry?.canvasData != null) {
      _loadCanvasData(widget.entry!.canvasData!);
    }
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final status = await SubscriptionService.instance.getStatus();
      setState(() => _isPro = status.isPro);
    } catch (e) {}
  }

  void _showProFontLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Bu font PRO üyelere özel ✨'),
      action: SnackBarAction(
        label: "PRO'ya Geç",
        onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const PremiumScreen())),
      ),
    ));
  }

  void _loadCanvasData(String canvasData) {
    try {
      final Map<String, dynamic> data = jsonDecode(canvasData);
      final bg = data['backgroundColor'];
      if (bg != null) _backgroundColor = Color(bg);

      if (data.containsKey('stickers')) {
        final stickers = data['stickers'] as List? ?? [];
        for (final s in stickers) {
          final type = s['type'] as String;
          final content = s['content'] as String?;
          final modelData = s['model'] as Map<String, dynamic>;
          if (type == 'image') {
            _stickers.add(_StickerItem(
                model: PictureModel.fromJson(modelData), type: type, content: content));
          } else {
            _stickers.add(_StickerItem(
                model: TextModel.fromJson(modelData), type: type, content: content));
          }
        }
      }

      if (data.containsKey('locations')) {
        final locs = data['locations'] as List? ?? [];
        _locations.addAll(locs.map((l) => _LocationItem.fromJson(l)));
      }

      if (data.containsKey('paths')) {
        final paths = data['paths'] as List? ?? [];
        _drawingPaths = paths.map((p) => DrawingPath.fromJson(p)).toList();
      }

      if (data.containsKey('elements')) {
        final elements = data['elements'] as List? ?? [];
        _legacyElements.addAll(elements.cast<Map<String, dynamic>>());
        final paths = data['paths'] as List? ?? [];
        _drawingPaths = paths.map((p) => DrawingPath.fromJson(p)).toList();
      }

      setState(() {});
    } catch (e) {}
  }

  bool get _isEmpty =>
      _stickers.isEmpty && _locations.isEmpty &&
          _drawingPaths.isEmpty && _legacyElements.isEmpty;

  Future<void> _onBackPressed() async {
    if (_isEmpty) { Navigator.pop(context); return; }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: const [
          Icon(Icons.edit_note_rounded, color: Color(0xFFC4956A), size: 22),
          SizedBox(width: 8),
          Text('Değişiklikler Kaydedilmedi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: Color(0xFF1C110A))),
        ]),
        content: const Text(
            'Sayfadan çıkarsanız henüz kaydetmediğiniz çizim ve anılar silinecektir.',
            style: TextStyle(fontSize: 13, color: Color(0xFF7C6A59), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Düzenlemeye Devam Et',
                style: TextStyle(color: Color(0xFFC4956A), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Çık', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) Navigator.pop(context);
  }

  Future<void> _saveCanvas() async {
    if (_isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sayfanız boş! Lütfen en az bir anı, fotoğraf veya çizim ekleyin.'),
        backgroundColor: Color(0xFF1C110A),
      ));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final textContent = _stickers.where((s) => s.type == 'text')
          .map((s) => s.content ?? '').join(' ');
      final firstLocation = _locations.isNotEmpty ? _locations.first : null;

      final entryData = {
        'textContent': textContent.isNotEmpty ? textContent : null,
        'locationName': firstLocation?.name,
        'lat': firstLocation?.lat,
        'lng': firstLocation?.lng,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'canvasData': '{}',
      };

      Entry entry;
      if (widget.entry != null) {
        entry = await EntryService.updateEntry(widget.journalId, widget.entry!.id, entryData);
      } else {
        entry = await EntryService.createEntry(widget.journalId, entryData);
      }

      for (var i = 0; i < _stickers.length; i++) {
        final item = _stickers[i];
        if (item.type == 'image' && item.content != null &&
            !item.content!.startsWith('http')) {
          try {
            final file = File(item.content!);
            final exists = await file.exists();
            if (!exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dosya bulunamadı: ${item.content}')));
              continue;
            }
            final url = await PhotoService.uploadDirectToCloudinary(item.content!);
            _stickers[i] = _StickerItem(
              model: PictureModel.fromUrl(url,
                  scale: (item.model as PictureModel).scale,
                  top: (item.model as PictureModel).top,
                  left: (item.model as PictureModel).left,
                  angle: (item.model as PictureModel).angle),
              type: 'image', content: url,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fotoğraf yükleme hatası: $e')));
          }
        }
      }

      final canvasData = jsonEncode({
        'backgroundColor': _backgroundColor.value,
        'stickers': _stickers.map((s) => s.toJson()).toList(),
        'locations': _locations.map((l) => l.toJson()).toList(),
        'paths': _drawingPaths.map((p) => p.toJson()).toList(),
      });

      await EntryService.updateEntry(widget.journalId, entry.id, {
        ...entryData, 'canvasData': canvasData,
      });

      InterstitialAdService.instance.onPageSaved();

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sayfa başarıyla kaydedildi! 🌿'),
          backgroundColor: Color(0xFF1C110A),
        ));
      }
    } on LimitReachedException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showLimitReachedSheet(context, limitType: 'page');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt sırasında bir hata oluştu!')));
      }
    }
  }

  bool _isPickingImage = false;

  Future<void> _addPhoto() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? image = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 90);
      if (image == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      // XFile.readAsBytes() picker'ın platforma özgü güvenli okuma
      // yolunu kullanır; ham File(image.path) bazı cihazlarda henüz
      // tam oluşmamış/okunamaz bir yol döndürüp PathNotFoundException'a
      // yol açabiliyor.
      final bytes = await image.readAsBytes();
      final savedFile = await File('${appDir.path}/$fileName').writeAsBytes(bytes);
      setState(() {
        _stickers.add(_StickerItem(
          model: PictureModel.fromUrl(savedFile.path, scale: 1.5),
          type: 'image', content: savedFile.path,
        ));
      });

      // 1. katman: fotoğrafın EXIF'inde GPS varsa ücretsiz ve anında ekle.
      final gps = await PhotoService.extractExifGps(savedFile.path);
      if (gps != null) {
        final name = await PhotoService.reverseGeocode(gps['lat']!, gps['lng']!);
        if (name != null) {
          if (mounted) {
            setState(() => _locations.add(_LocationItem(
                name: name, lat: gps['lat'], lng: gps['lng'])));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('📍 "$name" fotoğraftan otomatik eklendi')));
          }
          return;
        }
      }

      // 2-3. katman (Google Vision + Claude fallback) EXIF yoksa PRO'ya sunulur.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('📍 Bu fotoğrafın konumunu tahmin edeyim mi?'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Tahmin Et',
            onPressed: () => _isPro
                ? _estimateLocationFromPhoto(savedFile.path)
                : _showAiLocationLockedMessage(),
          ),
        ));
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _showAiLocationLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('AI konum tahmini PRO üyelere özel ✨'),
      action: SnackBarAction(
        label: "PRO'ya Geç",
        onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const PremiumScreen())),
      ),
    ));
  }

  Future<void> _estimateLocationFromPhoto(String filePath) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🔍 Konum tahmin ediliyor...'),
      duration: Duration(seconds: 3),
    ));
    try {
      final guess = await PhotoService.estimateLocation(filePath);
      if (!mounted) return;
      setState(() => _locations.add(
          _LocationItem(name: guess.name, lat: guess.lat, lng: guess.lng)));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 "${guess.name}" eklendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Konum tahmin edilemedi, tekrar dene.')));
    }
  }

  void _addText() {
    final controller = TextEditingController();
    Color selectedColor = const Color(0xFF2C2420);
    double selectedSize = 20.0;
    String selectedFont = 'Plus Jakarta Sans';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 16,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 44, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                        borderRadius: BorderRadius.circular(2)))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Anı / Not Yazısı',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                          color: Color(0xFF1C110A))),
                  Text('Boyut: ${selectedSize.toInt()}px',
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.bold, color: Color(0xFFC4956A))),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: controller, maxLines: 4, autofocus: true,
                  style: GoogleFonts.getFont(selectedFont,
                      fontSize: selectedSize * 0.75, color: selectedColor, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Şimdi hissettiklerin, mekanın kokusu, aldığın bir not...',
                    hintStyle: const TextStyle(color: Color(0xFF9E8E81), fontSize: 14),
                    filled: true, fillColor: const Color(0xFFFAF7F2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFEADBCE))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFC4956A), width: 1.5)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Font seçimi
                const Text('Yazı Stili',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Color(0xFF7C6A59))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    {'name': 'Plus Jakarta Sans', 'label': 'Modern'},
                    {'name': 'Playfair Display', 'label': 'Serif'},
                    {'name': 'Caveat', 'label': 'El Yazısı'},
                    {'name': 'Dancing Script', 'label': 'Kaligrafi'},
                    {'name': 'Roboto Mono', 'label': 'Mono'},
                    {'name': 'Lora', 'label': 'Klasik'},
                    {'name': 'Merriweather', 'label': 'Gazete'},
                    {'name': 'Pacifico', 'label': 'Eğlenceli'},
                    {'name': 'Satisfy', 'label': 'İmza'},
                    {'name': 'Sacramento', 'label': 'Zarif'},
                    {'name': 'Abril Fatface', 'label': 'Kalın'},
                    {'name': 'Cinzel', 'label': 'Antik'},
                    {'name': 'Great Vibes', 'label': 'Romantik'},
                    {'name': 'Permanent Marker', 'label': 'Marker'},
                    {'name': 'Special Elite', 'label': 'Daktilo'},
                    {'name': 'Amatic SC', 'label': 'El Baskı'},
                    {'name': 'Josefin Sans', 'label': 'Minimal'},
                    {'name': 'Raleway', 'label': 'Şık'},
                  ].map((font) {
                    final isLocked = !_isPro &&
                        !kFreeCanvasFonts.contains(font['name']);
                    return GestureDetector(
                    onTap: () => isLocked
                        ? _showProFontLockedMessage()
                        : setSheetState(() => selectedFont = font['name']!),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedFont == font['name']
                            ? const Color(0xFFC4956A) : const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selectedFont == font['name']
                                ? const Color(0xFFC4956A) : const Color(0xFFEADBCE)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isLocked) ...[
                          const Icon(Icons.lock_rounded,
                              size: 11, color: Color(0xFF9E8E81)),
                          const SizedBox(width: 4),
                        ],
                        Text(font['label']!,
                            style: GoogleFonts.getFont(font['name']!,
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: isLocked
                                    ? const Color(0xFF9E8E81)
                                    : selectedFont == font['name']
                                        ? Colors.white
                                        : const Color(0xFF1C110A))),
                      ]),
                    ),
                  );}).toList()),
                ),

                const SizedBox(height: 14),
                // Renk seçimi
                const Text('Metin Rengi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Color(0xFF7C6A59))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    const Color(0xFF2C2420), const Color(0xFFC4956A),
                    const Color(0xFF1C110A), Colors.white, Colors.blue.shade700,
                    Colors.green.shade700, Colors.purple.shade700, Colors.red.shade600,
                    Colors.orange.shade700, Colors.teal.shade700,
                    const Color(0xFF8B6F5E),
                  ].map((color) => GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = color),
                    child: Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: Border.all(
                            color: selectedColor == color
                                ? const Color(0xFFC4956A) : const Color(0xFFEADBCE),
                            width: selectedColor == color ? 3 : 1),
                      ),
                      child: selectedColor == color
                          ? Icon(Icons.check, size: 16,
                          color: color == Colors.white ? Colors.black : Colors.white)
                          : null,
                    ),
                  )).toList()),
                ),

                const SizedBox(height: 14),
                // Boyut seçimi
                Row(children: [
                  const Text('Yazı Boyutu',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF7C6A59))),
                  Expanded(child: Slider(
                    value: selectedSize, min: 14, max: 48,
                    activeColor: const Color(0xFFC4956A),
                    inactiveColor: const Color(0xFFEADBCE),
                    onChanged: (v) => setSheetState(() => selectedSize = v),
                  )),
                  Text('${selectedSize.toInt()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7C6A59),
                          fontWeight: FontWeight.w600)),
                ]),

                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Vazgeç',
                        style: TextStyle(color: Color(0xFF7C6A59),
                            fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          _stickers.add(_StickerItem(
                            model: TextModel.fromText(
                              controller.text.trim(),
                              textStyle: GoogleFonts.getFont(
                                selectedFont,
                                fontSize: selectedSize,
                                color: selectedColor,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            type: 'text',
                            content: controller.text.trim(),
                          ));
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4956A),
                      foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Sayfaya Ekle',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  )),
                ]),
              ]),
        ),
      ),
    );
  }

  void _addEmoji() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.9, minChildSize: 0.45,
        expand: false,
        builder: (context, scrollController) => Column(children: [
          Container(width: 44, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Emoji Ekle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: Color(0xFF1C110A))),
                  Text('Seyahat & Keşif',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7C6A59))),
                ]),
          ),
          const SizedBox(height: 8),
          Expanded(child: ListView(
            controller: scrollController, padding: const EdgeInsets.all(16),
            children: {
              '✈️ Seyahat ve Rota': ['✈️','🚂','⛵','🚗','🏕️','🗺️','🧳','🎒','🚀','🚁','⛴️','🚢','🛳️','🚤','🚲'],
              '🌍 Şehirler ve Yerler': ['🏔️','🌊','🏖️','🌅','🗼','🏰','🌃','🌉','🌴','🏝️','🗽','🏯','⛩️','🕌','🏛️'],
              '❤️ Duygular ve Işıltı': ['❤️','⭐','🌟','💫','🎉','🥰','😊','🤩','💕','🙌','🥳','😍','🤗','💖','✨'],
              '📸 Anlar ve Aktiviteler': ['📸','🎭','🎪','🎨','🎵','🍜','🥂','🌺','🎊','🎁','🎬','🎤','🎸','🍷','🥗'],
              '🌙 Gökyüzü ve Doğa': ['☀️','🌙','⭐','🌈','🌸','🍂','❄️','🌊','⚡','🌤️','🌧️','🌨️','🌪️','🌫️','🌬️'],
              '🍕 Yerel Lezzetler': ['🍜','🍣','🥐','🍕','🌮','🥘','🍛','🥗','🍰','☕','🧃','🍹','🥤','🍦','🧁'],
            }.entries.map((category) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(category.key,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7C6A59),
                          fontWeight: FontWeight.w700)),
                ),
                Wrap(spacing: 10, runSpacing: 10,
                    children: category.value.map((emoji) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _stickers.add(_StickerItem(
                            model: TextModel.fromText(emoji,
                                textStyle: const TextStyle(fontSize: 52)),
                            type: 'emoji', content: emoji,
                          ));
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEADBCE)),
                        ),
                        child: Center(child: Text(emoji,
                            style: const TextStyle(fontSize: 28))),
                      ),
                    )).toList()),
                const SizedBox(height: 20),
              ],
            )).toList(),
          )),
        ]),
      ),
    );
  }

  void _addLocation() {
    final controller = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: const [
                Icon(Icons.pin_drop_rounded, color: Color(0xFFC4956A), size: 22),
                SizedBox(width: 8),
                Text('Ziyaret Edilen Konum Ekle',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1C110A))),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: controller, autofocus: true,
                onChanged: (value) async {
                  if (value.length < 2) {
                    setSheetState(() => suggestions = []);
                    return;
                  }
                  setSheetState(() => isSearching = true);
                  try {
                    final response = await http.get(
                      Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(value)}&format=json&limit=5&accept-language=tr'),
                      headers: {'User-Agent': 'Seyahood/1.0'},
                    );
                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body) as List;
                      setSheetState(() {
                        suggestions = data.map((e) => {
                          'name': e['display_name'],
                          'lat': double.parse(e['lat']),
                          'lng': double.parse(e['lon']),
                        }).toList();
                        isSearching = false;
                      });
                    }
                  } catch (e) {
                    setSheetState(() => isSearching = false);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Şehir, mekan, anıt ara (Roma, Eyfel, Karaköy...)',
                  hintStyle: const TextStyle(color: Color(0xFF9E8E81), fontSize: 13),
                  filled: true, fillColor: const Color(0xFFFAF7F2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF7C6A59), size: 20),
                  suffixIcon: isSearching
                      ? const Padding(padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFC4956A))))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true, itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final s = suggestions[index];
                    final parts = s['name'].toString().split(',');
                    final mainName = parts[0].trim();
                    final subName = parts.length > 1
                        ? parts.sublist(1).join(',').trim() : '';
                    return ListTile(
                      leading: Container(width: 38, height: 38,
                          decoration: const BoxDecoration(
                              color: Color(0xFFF7EBE1), shape: BoxShape.circle),
                          child: const Icon(Icons.location_on,
                              color: Color(0xFFC4956A), size: 20)),
                      title: Text(mainName,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C110A))),
                      subtitle: subName.isNotEmpty
                          ? Text(subName,
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFF7C6A59)),
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () {
                        setState(() {
                          _locations.add(_LocationItem(
                              name: mainName,
                              lat: s['lat'], lng: s['lng']));
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showDrawingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 44, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                        borderRadius: BorderRadius.circular(2)))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Çizim & Fırça Ayarları',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                          color: Color(0xFF1C110A))),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isDrawingMode = true);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.brush, size: 16),
                    label: const Text('Çizmeye Başla'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4956A),
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text('Fırça Rengi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Color(0xFF7C6A59))),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  const Color(0xFF2C2420), const Color(0xFFC4956A), Colors.white,
                  Colors.black87, const Color(0xFF8B6F5E), Colors.blue.shade600,
                  Colors.green.shade600, Colors.purple.shade600, Colors.red.shade500,
                  Colors.orange.shade500, const Color(0xFFFFD9A0),
                  const Color(0xFFA0D4FF), const Color(0xFFB3FFB3),
                  const Color(0xFFFFB3D9), const Color(0xFFD4A0FF),
                ].map((color) => GestureDetector(
                  onTap: () {
                    setModalState(() => _drawingColor = color);
                    setState(() => _drawingColor = color);
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(
                          color: _drawingColor == color
                              ? const Color(0xFFC4956A) : const Color(0xFFEADBCE),
                          width: _drawingColor == color ? 3 : 1),
                    ),
                    child: _drawingColor == color
                        ? Icon(Icons.check, size: 16,
                        color: color == Colors.white ? Colors.black : Colors.white)
                        : null,
                  ),
                )).toList()),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Fırça Kalınlığı',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF7C6A59))),
                  Expanded(child: Slider(
                    value: _drawingSize, min: 1, max: 24,
                    activeColor: const Color(0xFFC4956A),
                    inactiveColor: const Color(0xFFEADBCE),
                    onChanged: (v) {
                      setModalState(() => _drawingSize = v);
                      setState(() => _drawingSize = v);
                    },
                  )),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2), shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEADBCE))),
                    child: Center(child: Container(
                      width: _drawingSize.clamp(4, 20),
                      height: _drawingSize.clamp(4, 20),
                      decoration: BoxDecoration(color: _drawingColor,
                          shape: BoxShape.circle),
                    )),
                  ),
                ]),
                if (_drawingPaths.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _drawingPaths.clear());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                      label: const Text('Çizimleri Temizle',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
              ]),
        ),
      ),
    );
  }

  void _showBackgroundPicker() {
    final colors = [
      const Color(0xFFFAF7F2), const Color(0xFFFFFFFF), const Color(0xFFF5ECD7),
      const Color(0xFFEDE8E3), const Color(0xFFE8F0FE), const Color(0xFFE6F4EA),
      const Color(0xFFFCE4EC), const Color(0xFFF3E5F5), const Color(0xFFFFF8E1),
      const Color(0xFFE0F2F1), const Color(0xFFFBE9E7), const Color(0xFF1A1A2E),
      const Color(0xFF2C2420), const Color(0xFF16213E),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 44, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                      borderRadius: BorderRadius.circular(2)))),
              const Text('Defter Sayfası Rengi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: Color(0xFF1C110A))),
              const SizedBox(height: 6),
              const Text('Sayfanızın havasına uygun bir defter kağıdı seçin',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7C6A59))),
              const SizedBox(height: 18),
              Wrap(spacing: 12, runSpacing: 12, children: colors.map((color) =>
                  GestureDetector(
                    onTap: () {
                      setState(() => _backgroundColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _backgroundColor == color
                                ? const Color(0xFFC4956A) : const Color(0xFFEADBCE),
                            width: _backgroundColor == color ? 3 : 1),
                      ),
                      child: _backgroundColor == color
                          ? Icon(Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? const Color(0xFF1C110A) : Colors.white,
                          size: 20)
                          : null,
                    ),
                  )).toList()),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppTheme.navDark,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppTheme.navDark,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFEADBCE), size: 16),
            ),
            onPressed: _onBackPressed,
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Sayfa Tasarla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFFFAF7F2))),
            Text('Seyahat Defteri Tuvali',
                style: TextStyle(fontSize: 10, color: Color(0xFFC4956A),
                    fontWeight: FontWeight.w500)),
          ]),
          actions: _buildAppBarActions(),
        ),
        body: Column(children: [
          Expanded(
            child: Stack(alignment: Alignment.topCenter, children: [
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 28, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedLocationIndex = null;
                        _selectedStickerIndex = null;
                        for (final s in _stickers) {
                          if (s.model is TextModel)
                            (s.model as TextModel).isSelected = false;
                          if (s.model is PictureModel)
                            (s.model as PictureModel).isSelected = false;
                        }
                      }),
                      onPanStart: _isDrawingMode ? (d) {
                        setState(() {
                          _currentPath = DrawingPath(
                              points: [d.localPosition],
                              color: _drawingColor,
                              strokeWidth: _drawingSize);
                          _drawingPaths.add(_currentPath!);
                        });
                      } : null,
                      onPanUpdate: _isDrawingMode
                          ? (d) => setState(() =>
                          _currentPath?.points.add(d.localPosition))
                          : null,
                      onPanEnd: _isDrawingMode
                          ? (d) => setState(() => _currentPath = null)
                          : null,
                      child: Stack(children: [
                        CustomPaint(
                            painter: _DottedBackgroundPainter(_backgroundColor),
                            size: Size.infinite),
                        ..._legacyElements.map((e) => _buildLegacyElement(e)),
                        CustomPaint(
                            painter: _DrawingPainter(_drawingPaths),
                            size: Size.infinite),
                        ..._stickers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return StickerWidget(
                            boundWidth: constraints.maxWidth,
                            boundHeight: constraints.maxHeight,
                            data: item.model,
                            closeIcon: const Icon(Icons.close,
                                color: Colors.black, size: 8),
                            resizeIcon: const Icon(Icons.open_in_full,
                                color: Colors.black, size: 8),
                            rotateIcon: const Icon(Icons.rotate_right,
                                color: Colors.black, size: 8),
                            onCancel: () => setState(() {
                              _stickers.removeAt(idx);
                              if (_selectedStickerIndex == idx) {
                                _selectedStickerIndex = null;
                              } else if (_selectedStickerIndex != null &&
                                  _selectedStickerIndex! > idx) {
                                _selectedStickerIndex = _selectedStickerIndex! - 1;
                              }
                            }),
                            onTap: () {
                              setState(() {
                                _selectedStickerIndex = idx;
                                for (var i = 0; i < _stickers.length; i++) {
                                  if (_stickers[i].model is TextModel) {
                                    (_stickers[i].model as TextModel).isSelected = i == idx;
                                  } else if (_stickers[i].model is PictureModel) {
                                    (_stickers[i].model as PictureModel).isSelected = i == idx;
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                        ..._locations.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final loc = entry.value;
                          final isSelected = _selectedLocationIndex == idx;
                          return Stack(clipBehavior: Clip.none, children: [
                            Positioned(
                              left: loc.x, top: loc.y,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                _selectedLocationIndex = isSelected ? null : idx),
                                onPanUpdate: (d) => setState(() {
                                  loc.x += d.delta.dx;
                                  loc.y += d.delta.dy;
                                }),
                                child: Transform.rotate(
                                  angle: loc.angle,
                                  child: Transform.scale(
                                    scale: loc.scale,
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      key: loc.key,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: loc.color,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [BoxShadow(
                                            color: loc.color.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))],
                                        border: isSelected ? Border.all(
                                            color: Colors.white, width: 2.5) : null,
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 5),
                                            Text(loc.name, style: TextStyle(
                                                color: loc.color.computeLuminance() > 0.5
                                                    ? Colors.black87 : Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                          ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                left: loc.x, top: loc.y - 44,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.navDark.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8)],
                                  ),
                                  child: Row(children: [
                                    const Color(0xFFC4956A), const Color(0xFFE8D5C4),
                                    const Color(0xFF2C2420), const Color(0xFF8B6F5E),
                                    const Color(0xFF6B8F71), const Color(0xFF7B8FA1),
                                    const Color(0xFFB5838D),
                                  ].map((color) => GestureDetector(
                                    onTap: () => setState(() => loc.color = color),
                                    child: Container(
                                      width: 24, height: 24,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle,
                                        border: Border.all(
                                            color: loc.color == color
                                                ? Colors.white : Colors.transparent,
                                            width: 2),
                                      ),
                                    ),
                                  )).toList()),
                                ),
                              ),
                            if (isSelected)
                              Positioned(
                                left: loc.x - 12, top: loc.y - 12,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _locations.removeAt(idx);
                                    _selectedLocationIndex = null;
                                  }),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            if (isSelected)
                              Builder(builder: (context) {
                                double w = 100;
                                if (loc.key.currentContext != null) {
                                  final box = loc.key.currentContext!
                                      .findRenderObject() as RenderBox?;
                                  if (box != null) w = box.size.width * loc.scale;
                                }
                                return Positioned(
                                  left: loc.x + w - 10, top: loc.y - 10,
                                  child: GestureDetector(
                                    onPanUpdate: (d) => setState(
                                            () => loc.angle += d.delta.dx * 0.03),
                                    child: Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFC4956A),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.rotate_right,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                );
                              }),
                            if (isSelected)
                              Builder(builder: (context) {
                                double w = 100, h = 36;
                                if (loc.key.currentContext != null) {
                                  final box = loc.key.currentContext!
                                      .findRenderObject() as RenderBox?;
                                  if (box != null) {
                                    w = box.size.width * loc.scale;
                                    h = box.size.height * loc.scale;
                                  }
                                }
                                return Positioned(
                                  left: loc.x + w - 10, top: loc.y + h - 10,
                                  child: GestureDetector(
                                    onPanUpdate: (d) => setState(() =>
                                    loc.scale = (loc.scale + d.delta.dx * 0.01)
                                        .clamp(0.5, 3.0)),
                                    child: Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFC4956A),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.open_in_full,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                );
                              }),
                          ]);
                        }).toList(),
                        if (_isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC4956A).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFC4956A).withOpacity(0.2),
                                          width: 1.5),
                                    ),
                                    child: const Icon(Icons.auto_stories_rounded,
                                        size: 34, color: Color(0xFFC4956A)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Sayfan Henüz Boş',
                                      style: TextStyle(fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1C110A))),
                                  const SizedBox(height: 6),
                                  const Text(
                                      'Fotoğraf, anı yazısı, konum veya çizim ekleyin.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12,
                                          color: Color(0xFF7C6A59), height: 1.4)),
                                  const SizedBox(height: 18),
                                  Wrap(spacing: 8, children: [
                                    _buildQuickAddChip('+ Fotoğraf', _addPhoto),
                                    _buildQuickAddChip('+ Yazı', _addText),
                                    _buildQuickAddChip('+ Konum', _addLocation),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        if (_isDrawingMode)
                          Positioned(
                            top: 14, left: 0, right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.navDark.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFFC4956A).withOpacity(0.4),
                                      width: 1),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4))],
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(
                                        color: _drawingColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Çizim Modu Aktif',
                                      style: TextStyle(color: Colors.white,
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => setState(() => _isDrawingMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFC4956A),
                                          borderRadius: BorderRadius.circular(12)),
                                      child: const Text('Tamamla',
                                          style: TextStyle(color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    );
                  }),
                ),
              ),
              // Washi tape efekti
              Positioned(
                top: 2,
                child: Container(
                  width: 90, height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C5B0).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                ),
              ),
            ]),
          ),
          _buildToolbar(),
        ]),
      ),
    );
  }

  Widget _buildQuickAddChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEADBCE)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.bold, color: Color(0xFFC4956A))),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final hasAnything = _stickers.isNotEmpty || _locations.isNotEmpty;
    final hasSelection = _selectedStickerIndex != null;
    final canGoFront = hasSelection && _selectedStickerIndex! < _stickers.length - 1;
    final canGoBack = hasSelection && _selectedStickerIndex! > 0;

    return [
      if (hasAnything)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Kopyala',
              icon: Icon(Icons.copy_rounded,
                  color: hasSelection ? Colors.white : Colors.white24, size: 17),
              onPressed: hasSelection
                  ? () => setState(() => _clipboard = _stickers[_selectedStickerIndex!])
                  : null,
            ),
            IconButton(
              tooltip: 'Öne Getir',
              icon: Icon(Icons.flip_to_front_rounded,
                  color: canGoFront ? Colors.white : Colors.white24, size: 17),
              onPressed: canGoFront ? () => setState(() {
                final item = _stickers.removeAt(_selectedStickerIndex!);
                _stickers.add(item);
                _selectedStickerIndex = _stickers.length - 1;
              }) : null,
            ),
            IconButton(
              tooltip: 'Arkaya Gönder',
              icon: Icon(Icons.flip_to_back_rounded,
                  color: canGoBack ? Colors.white : Colors.white24, size: 17),
              onPressed: canGoBack ? () => setState(() {
                final item = _stickers.removeAt(_selectedStickerIndex!);
                _stickers.insert(0, item);
                _selectedStickerIndex = 0;
              }) : null,
            ),
            if (_clipboard != null)
              IconButton(
                tooltip: 'Yapıştır',
                icon: const Icon(Icons.paste_rounded,
                    color: Color(0xFFC4956A), size: 17),
                onPressed: () {
                  final copy = _clipboard!;
                  setState(() {
                    _stickers.add(_StickerItem(
                      model: copy.type == 'image'
                          ? PictureModel.fromUrl(
                          (copy.model as PictureModel).stringUrl,
                          scale: (copy.model as PictureModel).scale)
                          : TextModel.fromText(
                          (copy.model as TextModel).name,
                          textStyle: (copy.model as TextModel).textStyle),
                      type: copy.type, content: copy.content,
                    ));
                  });
                },
              ),
          ]),
        ),
      const SizedBox(width: 6),
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFC4956A))),
        )
      else
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
          child: ElevatedButton.icon(
            onPressed: _saveCanvas,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4956A),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
    ];
  }

  Widget _buildLegacyElement(Map<String, dynamic> e) {
    final type = e['type'] as String;
    final content = e['content'] as String?;
    final x = (e['x'] as num? ?? 0).toDouble();
    final y = (e['y'] as num? ?? 0).toDouble();

    Widget child;
    if (type == 'photo' && content != null) {
      child = Container(
        padding: const EdgeInsets.all(8), color: Colors.white,
        child: content.startsWith('http')
            ? Image.network(content, width: 160, height: 160, fit: BoxFit.cover)
            : Image.file(File(content), width: 160, height: 160, fit: BoxFit.cover),
      );
    } else if (type == 'text') {
      child = Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8)),
        child: Text(content ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF2C2420))),
      );
    } else if (type == 'sticker') {
      child = Text(content ?? '⭐', style: const TextStyle(fontSize: 40));
    } else if (type == 'location') {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFC4956A),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(content ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    } else {
      return const SizedBox();
    }
    return Positioned(left: x, top: y, child: child);
  }

  Widget _buildToolbar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.navDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildTool(Icons.image_outlined, 'Fotoğraf', _addPhoto,
              enabled: !_isDrawingMode),
          _buildTool(Icons.text_fields_rounded, 'Yazı', _addText,
              enabled: !_isDrawingMode),
          _buildTool(Icons.emoji_emotions_outlined, 'Emoji', _addEmoji,
              enabled: !_isDrawingMode),
          _buildTool(
            Icons.draw_outlined, 'Çiz',
            _isDrawingMode
                ? () => setState(() => _isDrawingMode = false)
                : _showDrawingOptions,
            isActive: _isDrawingMode, enabled: true,
          ),
          _buildTool(Icons.location_on_outlined, 'Konum', _addLocation,
              enabled: !_isDrawingMode),
          _buildTool(Icons.palette_outlined, 'Arka Plan', _showBackgroundPicker,
              enabled: !_isDrawingMode),
        ]),
      ),
    );
  }

  Widget _buildTool(IconData icon, String label, VoidCallback onTap,
      {bool isActive = false, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC4956A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: isActive ? Colors.white
                  : enabled ? const Color(0xFFFAF7F2).withOpacity(0.85)
                  : Colors.white.withOpacity(0.2),
              size: 21),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: isActive ? Colors.white
                  : enabled ? const Color(0xFFFAF7F2).withOpacity(0.75)
                  : Colors.white.withOpacity(0.2))),
        ]),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  _DrawingPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.points.isEmpty) continue;
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final drawPath = Path();
      drawPath.moveTo(path.points.first.dx, path.points.first.dy);
      for (int i = 1; i < path.points.length; i++) {
        drawPath.lineTo(path.points[i].dx, path.points[i].dy);
      }
      canvas.drawPath(drawPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _DottedBackgroundPainter extends CustomPainter {
  final Color backgroundColor;
  _DottedBackgroundPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = backgroundColor.computeLuminance() < 0.4;
    final dotColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFD4C5B0).withOpacity(0.4);
    final paint = Paint()..color = dotColor..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBackgroundPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}