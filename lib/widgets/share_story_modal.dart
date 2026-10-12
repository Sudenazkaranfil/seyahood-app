import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/premium_screen.dart';

/// Kart Şablon Tipleri
enum CardTemplate {
  classicParchment,
  polaroidMinimal,
  cityCollector,
  filmStrip,
  vintageGazette,
  vintagePassport,
}

/// Format Oranları
enum ShareFormat {
  story,
  square,
  portrait,
}

class ShareStoryModal extends StatefulWidget {
  final String journalTitle;
  final String locationName;
  final String date;
  final String? textContent;
  final String? photoUrl;
  final String username;
  final int pageIndex;
  final int totalPages;
  final bool initialIsPro;
  final bool initialIsPlus;

  const ShareStoryModal({
    Key? key,
    required this.journalTitle,
    required this.locationName,
    required this.date,
    this.textContent,
    this.photoUrl,
    required this.username,
    this.pageIndex = 0,
    this.totalPages = 1,
    this.initialIsPro = false,
    this.initialIsPlus = false,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required String journalTitle,
        required String locationName,
        required String date,
        String? textContent,
        String? photoUrl,
        required String username,
        int pageIndex = 0,
        int totalPages = 1,
        bool isPro = false,
        bool isPlus = false,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareStoryModal(
        journalTitle: journalTitle,
        locationName: locationName,
        date: date,
        textContent: textContent,
        photoUrl: photoUrl,
        username: username,
        pageIndex: pageIndex,
        totalPages: totalPages,
        initialIsPro: isPro,
        initialIsPlus: isPlus,
      ),
    );
  }

  @override
  State<ShareStoryModal> createState() => _ShareStoryModalState();
}

class _ShareStoryModalState extends State<ShareStoryModal> {
  late bool _isPro;
  late bool _isPlus;
  ShareFormat _format = ShareFormat.story;
  CardTemplate _selectedTemplate = CardTemplate.classicParchment;
  bool _showWatermark = true;
  bool _showCollectorBadge = true;
  bool _showLocationPill = true;
  bool _isProcessing = false;

  final GlobalKey _cardRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isPro = widget.initialIsPro;
    _isPlus = widget.initialIsPlus;
    _showWatermark = !(_isPro || _isPlus);
  }

  bool _isTemplatePro(CardTemplate template) {
    return template == CardTemplate.filmStrip ||
        template == CardTemplate.vintageGazette ||
        template == CardTemplate.vintagePassport;
  }

  void _onTemplateSelect(CardTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFC46B4E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC46B4E).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD5C2), size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seyahood Gezgin Kulübü (PRO)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C110A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '35mm Film Şeridi, Gazete Küpürü ve Filigransız paylaşım için Gezgin Kulübü üyesi olun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF7C6A59), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Column(
                children: const [
                  _ProFeatureRow(icon: Icons.check_circle_rounded, text: 'Tamamen Filigransız Temiz Çıktı'),
                  SizedBox(height: 8),
                  _ProFeatureRow(icon: Icons.movie_filter_rounded, text: '35mm Analog Film Şeridi'),
                  SizedBox(height: 8),
                  _ProFeatureRow(icon: Icons.newspaper_rounded, text: 'The Chronicle Gazete Manşeti'),
                  SizedBox(height: 8),
                  _ProFeatureRow(icon: Icons.approval_rounded, text: 'Konsolosluk Pasaport Damgası'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC46B4E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const PremiumScreen()));
                },
                child: const Text(
                  "PRO'ya Geç",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShareOrDownload() async {
    if (_isTemplatePro(_selectedTemplate) && !_isPro) {
      _showProUpgradeDialog();
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final boundary = _cardRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final pixelRatio = _isPro ? 3.0 : (_isPlus ? 2.0 : 1.0);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/seyahood_kart.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '✈️ ${widget.journalTitle} — ${widget.locationName}\n'
            '@${widget.username} · Seyahood',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşılamadı, tekrar dene!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC46B4E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Paylaşım Stüdyosu',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C110A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (_isPro || _isPlus) return;
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const PremiumScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isPro ? const Color(0xFFC46B4E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: _isPro ? Colors.white : const Color(0xFFC46B4E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPro ? 'PRO Aktif' : (_isPlus ? 'Plus Aktif' : 'Ücretsiz Mod'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isPro ? Colors.white : const Color(0xFF7C6A59),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEADBCE)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C110A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CANLI KART ÖNİZLEME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white60,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _format == ShareFormat.story
                                    ? '9:16 Hikaye'
                                    : _format == ShareFormat.square
                                    ? '1:1 Kare'
                                    : '3:4 Portre',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC4956A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: _cardRepaintKey,
                          child: _buildCardContainer(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '1. PAYLAŞIM FORMATI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF7C6A59),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFormatBtn(ShareFormat.story, '📱 9:16', 'Hikaye'),
                      const SizedBox(width: 8),
                      _buildFormatBtn(ShareFormat.square, '🖼️ 1:1', 'Kare Post'),
                      const SizedBox(width: 8),
                      _buildFormatBtn(ShareFormat.portrait, '📸 3:4', 'Portre'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. KART ŞABLONU (6 SEÇENEK)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Color(0xFF7C6A59),
                        ),
                      ),
                      Text(
                        _isTemplatePro(_selectedTemplate) ? '👑 PRO Tasarım' : '🌿 Ücretsiz',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC46B4E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTemplateCard(
                        template: CardTemplate.classicParchment,
                        title: 'Klasik Parşömen',
                        subtitle: 'Defter sayfası',
                        isPro: false,
                      ),
                      _buildTemplateCard(
                        template: CardTemplate.polaroidMinimal,
                        title: 'Polaroid Çerçeve',
                        subtitle: 'Minimalist anı',
                        isPro: false,
                      ),
                      _buildTemplateCard(
                        template: CardTemplate.cityCollector,
                        title: 'Koleksiyoner Şehir',
                        subtitle: 'Rozet & edisyon',
                        isPro: false,
                      ),
                      _buildTemplateCard(
                        template: CardTemplate.filmStrip,
                        title: '35mm Film Şeridi',
                        subtitle: 'Sinematik negatif',
                        isPro: true,
                      ),
                      _buildTemplateCard(
                        template: CardTemplate.vintageGazette,
                        title: 'Gazete Küpürü',
                        subtitle: 'The Chronicle',
                        isPro: true,
                      ),
                      _buildTemplateCard(
                        template: CardTemplate.vintagePassport,
                        title: 'Pasaport Damgası',
                        subtitle: 'Konsolosluk vizesi',
                        isPro: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '3. KART DETAYLARI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF7C6A59),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildToggleTile(
                    icon: Icons.bookmark_added_rounded,
                    title: 'Rozet & Seri Bilgileri',
                    value: _showCollectorBadge,
                    onChanged: (val) => setState(() => _showCollectorBadge = val),
                  ),
                  const SizedBox(height: 6),
                  _buildToggleTile(
                    icon: Icons.location_on_rounded,
                    title: 'Şehir & Konum Başlığı',
                    value: _showLocationPill,
                    onChanged: (val) => setState(() => _showLocationPill = val),
                  ),
                  const SizedBox(height: 6),
                  _buildToggleTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Seyahood Filigranı',
                    subtitle: (_isPro || _isPlus)
                        ? 'Plus/PRO ile kaldırılabilir'
                        : 'Kaldırmak için Plus veya PRO gereklidir 🔒',
                    value: _showWatermark,
                    isLocked: !(_isPro || _isPlus),
                    onChanged: (val) {
                      if (!(_isPro || _isPlus)) {
                        _showProUpgradeDialog();
                        return;
                      }
                      setState(() => _showWatermark = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEADBCE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC46B4E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: _isProcessing ? null : _handleShareOrDownload,
                      icon: _isProcessing
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isProcessing
                            ? 'Kart Hazırlanıyor...'
                            : _isTemplatePro(_selectedTemplate) && !_isPro
                            ? 'PRO ile Paylaş & İndir'
                            : 'Seyahat Kartını İndir / Paylaş',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '✈️ ${widget.journalTitle} - ${widget.locationName} | Seyahood Seyahat Günlüğü',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bağlantı panoya kopyalandı!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C6A59)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF7F2),
                    side: const BorderSide(color: Color(0xFFEADBCE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer() {
    double width = 260;
    double height = 400;

    if (_format == ShareFormat.square) {
      width = 280;
      height = 280;
    } else if (_format == ShareFormat.portrait) {
      width = 270;
      height = 360;
    }

    Color bgColor = const Color(0xFFF7F3EB);
    Color textColor = const Color(0xFF1C110A);
    Border? border = Border.all(color: const Color(0xFFE2D5C3), width: 3);

    if (_selectedTemplate == CardTemplate.polaroidMinimal) {
      bgColor = Colors.white;
      border = Border.all(color: Colors.grey.shade300, width: 1);
    } else if (_selectedTemplate == CardTemplate.cityCollector) {
      bgColor = const Color(0xFF18110D);
      textColor = const Color(0xFFFAF7F2);
      border = Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2);
    } else if (_selectedTemplate == CardTemplate.filmStrip) {
      bgColor = const Color(0xFF0E0C0B);
      textColor = Colors.white;
      border = Border.all(color: const Color(0xFF1F1B18), width: 3);
    } else if (_selectedTemplate == CardTemplate.vintageGazette) {
      bgColor = const Color(0xFFF4ECE1);
      textColor = const Color(0xFF1C110A);
      border = Border.all(color: const Color(0xFF3A2D25), width: 3);
    } else if (_selectedTemplate == CardTemplate.vintagePassport) {
      bgColor = const Color(0xFFFAF7F2);
      textColor = const Color(0xFF1C110A);
      border = Border.all(color: const Color(0xFFC46B4E), width: 2);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _selectedTemplate == CardTemplate.filmStrip
                        ? '🎞️'
                        : _selectedTemplate == CardTemplate.vintageGazette
                        ? '📰'
                        : _selectedTemplate == CardTemplate.cityCollector
                        ? '🏛️'
                        : '✈️',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedTemplate == CardTemplate.filmStrip
                        ? '35MM KODACHROME'
                        : _selectedTemplate == CardTemplate.vintageGazette
                        ? 'THE WANDERLUST'
                        : _selectedTemplate == CardTemplate.cityCollector
                        ? 'ŞEHİR KOLEKSİYONU'
                        : 'Seyahood',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _selectedTemplate == CardTemplate.cityCollector
                          ? const Color(0xFFD4AF37)
                          : _selectedTemplate == CardTemplate.filmStrip
                          ? const Color(0xFFFF7A30)
                          : textColor,
                    ),
                  ),
                ],
              ),
              Text(
                'S.${widget.pageIndex + 1}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTemplateContent(textColor),
          ),
          if (_showWatermark)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC46B4E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  '✈️  Seyahood Seyahat Günlüğü',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateContent(Color textColor) {
    if (_selectedTemplate == CardTemplate.filmStrip) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
                  (index) => Container(
                width: 8,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1C1A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.photoUrl != null)
                    Image.network(widget.photoUrl!, fit: BoxFit.cover)
                  else
                    const Center(child: Icon(Icons.photo_rounded, color: Colors.white30, size: 40)),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Text(
                      "'26 09 13",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF5500),
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
                  (index) => Container(
                width: 8,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1C1A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_selectedTemplate == CardTemplate.vintageGazette) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF4EB),
          border: Border.all(color: const Color(0xFF2E231C), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.locationName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF1C110A),
                ),
              ),
            ),
            const Divider(color: Color(0xFF2E231C), thickness: 1, height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        border: Border.all(color: const Color(0xFF2E231C)),
                      ),
                      child: widget.photoUrl != null
                          ? Image.network(widget.photoUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.newspaper_rounded, color: Colors.black45),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Text(
                      widget.textContent ?? 'Yeni rotalar ve unutulmaz hatıralar.',
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Serif',
                        fontStyle: FontStyle.italic,
                        fontSize: 8,
                        color: Color(0xFF3E3027),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTemplate == CardTemplate.cityCollector) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.photoUrl != null)
                    Image.network(widget.photoUrl!, fit: BoxFit.cover)
                  else
                    const Center(child: Icon(Icons.location_city_rounded, color: Colors.white24, size: 40)),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF18110D)],
                        ),
                      ),
                      child: Text(
                        widget.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 ${widget.date}',
                style: const TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'Monospace'),
              ),
              if (_showCollectorBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '★ ROZET',
                    style: TextStyle(color: Color(0xFF18110D), fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.photoUrl != null
                ? Image.network(widget.photoUrl!, fit: BoxFit.cover, width: double.infinity)
                : const Center(child: Icon(Icons.image_rounded, color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 8),
        if (_showLocationPill)
          Text(
            widget.locationName,
            style: const TextStyle(color: Color(0xFFC46B4E), fontSize: 9, fontWeight: FontWeight.bold),
          ),
        Text(
          widget.journalTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFormatBtn(ShareFormat format, String title, String subtitle) {
    final isSelected = _format == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _format = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1C110A) : const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1C110A) : const Color(0xFFEADBCE),
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1C110A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : const Color(0xFF7C6A59),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required CardTemplate template,
    required String title,
    required String subtitle,
    required bool isPro,
  }) {
    final isSelected = _selectedTemplate == template;
    return GestureDetector(
      onTap: () => _onTemplateSelect(template),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF7F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC46B4E) : const Color(0xFFEADBCE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1C110A)),
                  ),
                ),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC46B4E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, color: Color(0xFF7C6A59)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    bool isLocked = false,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFC46B4E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1C110A))),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF7C6A59))),
              ],
            ),
          ),
          if (isLocked)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.lock_rounded, size: 14, color: Color(0xFFC46B4E)),
            ),
          Switch(
            value: value,
            activeColor: const Color(0xFFC46B4E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ProFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFC46B4E)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF523F31))),
      ],
    );
  }
}