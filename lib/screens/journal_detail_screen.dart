import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/journal.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/journal_service.dart';
import '../services/subscription_service.dart';
import 'canvas_editor_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/share_story_modal.dart';

class JournalDetailScreen extends StatefulWidget {
  final Journal journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  List<Entry> _entries = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;
  String? _coverImageUrl;
  final GlobalKey _pageKey = GlobalKey();
  bool _isPro = false;
  bool _isPlus = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _coverImageUrl = widget.journal.coverImageUrl;
    _loadEntries();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final status = await SubscriptionService.instance.getStatus();
      setState(() {
        _isPro = status.isPro;
        _isPlus = status.isPlus;
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries({bool keepPosition = false}) async {
    final currentIndex = keepPosition ? _currentPage : 0;
    try {
      final entries = await EntryService.getEntries(widget.journal.id);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
      if (keepPosition && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && currentIndex < entries.length) {
            _pageController.jumpToPage(currentIndex);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _uploadCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    try {
      // Seçilen dosyayı kalıcı klasöre kopyala — bulutta yedeklenmiş
      // (henüz cihaza tam inmemiş) galeri fotoğraflarında picker'ın
      // döndürdüğü ham yol bazen anlık/okunamaz oluyor.
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(image.path).copy('${appDir.path}/$fileName');

      final url = await JournalService.uploadCover(widget.journal.id, savedFile.path);
      setState(() => _coverImageUrl = url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapak fotoğrafı güncellendi!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kapak fotoğrafı yüklenemedi, bulutta yedekli bir '
              'fotoğraf olabilir — galeriden tam indirip tekrar dene.')));
    }
  }

  void _showDeleteDialog(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sayfayı sil',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        content: Text('Bu sayfa ve içerisindeki anılar kalıcı olarak silinecek.',
            style: AppTheme.sansBody(size: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: AppTheme.sansBody(
                    color: AppTheme.textSecondary, weight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Sil',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final entry = _entries[index];
      setState(() {
        _entries.removeAt(index);
        if (_currentPage >= _entries.length && _currentPage > 0) {
          _currentPage = _entries.length - 1;
        }
      });
      try {
        await EntryService.deleteEntry(widget.journal.id, entry.id);
      } catch (e) {
        setState(() => _entries.insert(index, entry));
      }
    }
  }

  void _showVisibilityDialog() async {
    final newVisibility =
    widget.journal.visibility == 'PUBLIC' ? 'PRIVATE' : 'PUBLIC';
    try {
      await JournalService.updateJournal(
          widget.journal.id, widget.journal.title, newVisibility);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(newVisibility == 'PUBLIC'
                ? 'Ajanda herkese açık yapıldı 🌍'
                : 'Ajanda gizliye alındı 🔒')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellenemedi, tekrar dene!')));
    }
  }

  Color _getBackgroundColor(String? canvasData) {
    if (canvasData == null) return const Color(0xFFFAF7F2);
    try {
      final data = jsonDecode(canvasData);
      final bg = data['backgroundColor'];
      if (bg != null) return Color(bg);
    } catch (e) {}
    return const Color(0xFFFAF7F2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Column(children: [
          _buildCurvedHeader(),
          Expanded(
            child: _isLoading
                ? const JournalDetailSkeletonLoader()
                : _hasError
                ? ErrorView(onRetry: _loadEntries)
                : _entries.isEmpty
                ? _buildEmptyState()
                : _buildPageView(),
          ),
        ]),
        if (!_isLoading && _entries.isNotEmpty)
          _buildFloatingThumbnailDock(),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (context) =>
                    CanvasEditorScreen(journalId: widget.journal.id)));
            _loadEntries(keepPosition: true);
          },
          backgroundColor: AppTheme.terracotta,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navDark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(
            color: AppTheme.navDark.withOpacity(0.35),
            blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(widget.journal.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 17, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.journal.visibility == 'PUBLIC'
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : AppTheme.terracotta.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.journal.visibility == 'PUBLIC'
                                ? const Color(0xFF10B981).withOpacity(0.4)
                                : AppTheme.terracotta.withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.journal.visibility == 'PUBLIC' ? 'Açık' : 'Özel',
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: widget.journal.visibility == 'PUBLIC'
                                  ? const Color(0xFFBBEECE)
                                  : const Color(0xFFFFDCBF)),
                        ),
                      ),
                    ]),
                    Text('${_entries.length} Anı Sayfası',
                        style: AppTheme.sansBody(
                            size: 11, color: Colors.white.withOpacity(0.6))),
                  ]),
            ),
            if (_coverImageUrl != null)
              GestureDetector(
                onTap: _uploadCover,
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.terracotta, width: 1.5),
                    image: DecorationImage(
                        image: NetworkImage(_coverImageUrl!),
                        fit: BoxFit.cover),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: Colors.white, size: 20),
              onPressed: _showShareOptions,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'delete' && _entries.isNotEmpty) {
                  _showDeleteDialog(_currentPage);
                } else if (value == 'visibility') {
                  _showVisibilityDialog();
                } else if (value == 'cover') {
                  _uploadCover();
                } else if (value == 'share') {
                  _showShareOptions();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'share', child: Row(children: [
                  Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 18),
                  const SizedBox(width: 10),
                  Text('Hikaye Paylaş', style: AppTheme.sansBody()),
                ])),
                PopupMenuItem(value: 'cover', child: Row(children: [
                  Icon(Icons.photo_camera_outlined,
                      color: AppTheme.textPrimary, size: 18),
                  const SizedBox(width: 10),
                  Text('Kapak Fotoğrafı', style: AppTheme.sansBody()),
                ])),
                PopupMenuItem(value: 'visibility', child: Row(children: [
                  Icon(
                      widget.journal.visibility == 'PUBLIC'
                          ? Icons.lock_outline : Icons.public,
                      color: AppTheme.textPrimary, size: 18),
                  const SizedBox(width: 10),
                  Text(widget.journal.visibility == 'PUBLIC'
                      ? 'Özel yap' : 'Herkese aç',
                      style: AppTheme.sansBody()),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 10),
                  Text('Sayfayı sil',
                      style: AppTheme.sansBody(color: Colors.red.shade400)),
                ])),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(
                color: Color(0x14000000), blurRadius: 16,
                offset: Offset(0, 4))],
          ),
          child: const Icon(Icons.edit_note_rounded,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 18),
        Text('İlk sayfanı ekle',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('Sağ alttaki + butonuna tıkla',
            style: AppTheme.sansBody(size: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildPageView() {
    return Stack(children: [
      PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _entries.length,
        itemBuilder: (context, index) => _buildPage(_entries[index], index),
      ),
      if (_currentPage > 0)
        Positioned(
          left: 8, top: 0, bottom: 60,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.navDark.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      if (_currentPage < _entries.length - 1)
        Positioned(
          right: 8, top: 0, bottom: 60,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.navDark.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildPage(Entry entry, int index) {
    return GestureDetector(
      onTap: () async {
        final currentIndex = _currentPage;
        await Navigator.push(context, MaterialPageRoute(
            builder: (context) => CanvasEditorScreen(
                journalId: widget.journal.id, entry: entry)));
        await _loadEntries(keepPosition: true);
        if (mounted) {
          setState(() => _currentPage = currentIndex);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(currentIndex);
            }
          });
        }
      },
      child: RepaintBoundary(
        key: _currentPage == index ? _pageKey : GlobalKey(),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 72),
          decoration: BoxDecoration(
            color: _getBackgroundColor(entry.canvasData),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border, width: 0.8),
            boxShadow: [BoxShadow(
                color: const Color(0xFF2A1D15).withOpacity(0.12),
                blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaleX = constraints.maxWidth / 360.0;
                final scaleY = constraints.maxHeight / 600.0;
                final scale = scaleX < scaleY ? scaleX : scaleY;
                return Stack(children: [
                  CustomPaint(
                      painter: DottedBackgroundPainter(),
                      size: Size.infinite),
                  // Sol cilt gölgesi
                  Positioned(
                    left: 0, top: 0, bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (entry.canvasData != null)
                    ..._buildCanvasPreview(entry.canvasData!, scale)
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (entry.locationName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.terracotta,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(
                                        color: AppTheme.terracotta.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3))],
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 5),
                                        Text(entry.locationName!,
                                            style: AppTheme.sansBody(
                                                size: 12,
                                                weight: FontWeight.w700,
                                                color: Colors.white)),
                                      ]),
                                ),
                              if (entry.textContent != null) ...[
                                const SizedBox(height: 18),
                                Text('"${entry.textContent!}"',
                                    style: GoogleFonts.playfairDisplay(
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                        height: 1.6,
                                        fontStyle: FontStyle.italic),
                                    textAlign: TextAlign.center),
                              ],
                            ]),
                      ),
                    ),
                  Positioned(
                    top: 14, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.navDark.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${index + 1} / ${_entries.length}',
                          style: AppTheme.sansBody(
                              size: 11, weight: FontWeight.w700,
                              color: AppTheme.textSecondary)),
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 16,
                    child: Text(
                      entry.date != null
                          ? '${entry.date!.day} ${_getMonth(entry.date!.month)}'
                          : '',
                      style: AppTheme.sansBody(
                          size: 11, weight: FontWeight.w500,
                          color: AppTheme.textSecondary.withOpacity(0.65)),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingThumbnailDock() {
    return Positioned(
      bottom: 14 + MediaQuery.of(context).padding.bottom,
      left: 18,
      right: 74,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.navDark.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.terracotta.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final isSelected = index == _currentPage;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic),
              onLongPress: () => _showDeleteDialog(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 48 : 38,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.terracotta
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.6)
                        : Colors.white.withOpacity(0.12),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Center(
                  child: Text('S.${index + 1}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6))),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showShareOptions() {
    final entry = _entries.isNotEmpty ? _entries[_currentPage] : null;
    final username = widget.journal.username ?? '';
    final locationName = entry?.locationName ?? widget.journal.title;
    final date = entry?.date != null
        ? '${entry!.date!.day}.${entry.date!.month}.${entry.date!.year}'
        : '';
    final photoUrl = entry?.photoUrls.isNotEmpty == true
        ? entry!.photoUrls.first
        : null;

    Navigator.pop(context);
    ShareStoryModal.show(
      context,
      journalTitle: widget.journal.title,
      locationName: locationName,
      date: date,
      textContent: entry?.textContent,
      photoUrl: photoUrl,
      username: username,
      pageIndex: _currentPage,
      totalPages: _entries.length,
      isPro: _isPro,
      isPlus: _isPlus,
    );
  }

  List<Widget> _buildCanvasPreview(String canvasData, double scale) {
    try {
      final Map<String, dynamic> data = jsonDecode(canvasData);
      List<Widget> widgets = [];

      if (data.containsKey('stickers') || data.containsKey('locations')) {
        final stickers = (data['stickers'] as List?) ?? [];
        final locations = (data['locations'] as List?) ?? [];
        final paths = (data['paths'] as List?) ?? [];

        if (paths.isNotEmpty) {
          final drawingPaths =
          paths.map((p) => DrawingPath.fromJson(p)).toList();
          widgets.add(Positioned.fill(
              child: CustomPaint(
                  painter: DrawingPainter(drawingPaths, scale))));
        }

        for (final s in stickers.where((s) => s['type'] == 'image')) {
          final model = s['model'] as Map<String, dynamic>?;
          if (model == null) continue;
          final top = (model['top'] as num? ?? 0).toDouble() * scale;
          final left = (model['left'] as num? ?? 0).toDouble() * scale;
          final stickerScale = (model['scale'] as num? ?? 1.0).toDouble();
          final angle = (model['angle'] as num? ?? 0).toDouble();
          final url = model['url'] as String? ?? '';
          widgets.add(Positioned(
            left: left, top: top,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: stickerScale * scale,
                alignment: Alignment.topLeft,
                child: url.startsWith('http')
                    ? Image.network(url, width: 160, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 160))
                    : const SizedBox(),
              ),
            ),
          ));
        }

        for (final l in locations) {
          final name = l['name'] as String? ?? '';
          final x = (l['x'] as num? ?? 0).toDouble() * scale;
          final y = (l['y'] as num? ?? 0).toDouble() * scale;
          final color =
          l['color'] != null ? Color(l['color']) : AppTheme.terracotta;
          widgets.add(Positioned(
            left: x, top: y,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(name, style: TextStyle(
                      color: color.computeLuminance() > 0.5
                          ? Colors.black87 : Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ));
        }

        for (final s in stickers.where((s) => s['type'] != 'image')) {
          final type = s['type'] as String;
          final content = s['content'] as String?;
          final model = s['model'] as Map<String, dynamic>?;
          if (model == null) continue;
          final top = (model['top'] as num? ?? 0).toDouble() * scale;
          final left = (model['left'] as num? ?? 0).toDouble() * scale;
          final stickerScale = (model['scale'] as num? ?? 1.0).toDouble();
          final text = model['text'] as String? ?? content ?? '';
          final textStyleData = model['textStyle'] as Map<String, dynamic>?;
          final fontSize =
          (textStyleData?['fontSize'] as num? ?? 14).toDouble();
          final color = textStyleData?['color'] != null
              ? Color(textStyleData!['color']) : AppTheme.textPrimary;
          widgets.add(Positioned(
            left: left, top: top,
            child: Transform.scale(
              scale: stickerScale * scale,
              alignment: Alignment.topLeft,
              child: type == 'emoji'
                  ? Text(text, style: const TextStyle(fontSize: 46))
                  : Text(text, style: TextStyle(
                  fontSize: fontSize, color: color,
                  fontWeight: FontWeight.w600)),
            ),
          ));
        }
      } else {
        final elements = (data['elements'] as List?) ?? [];
        final paths = (data['paths'] as List?) ?? [];

        if (paths.isNotEmpty) {
          final drawingPaths =
          paths.map((p) => DrawingPath.fromJson(p)).toList();
          widgets.add(Positioned.fill(
              child: CustomPaint(
                  painter: DrawingPainter(drawingPaths, scale))));
        }

        for (final e in elements) {
          final type = e['type'];
          final content = e['content'];
          final x = (e['x'] as num).toDouble() * scale;
          final y = (e['y'] as num).toDouble() * scale;
          Widget child;
          if (type == 'text') {
            child = Container(
                padding: const EdgeInsets.all(6),
                constraints: BoxConstraints(maxWidth: 120 * scale),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(content ?? '',
                    style: TextStyle(
                        fontSize: 9 * scale,
                        color: AppTheme.textPrimary)));
          } else if (type == 'photo') {
            child = content.startsWith('http')
                ? Image.network(content,
                width: 80 * scale, height: 80 * scale,
                fit: BoxFit.cover)
                : const SizedBox();
          } else if (type == 'sticker') {
            child = Text(content ?? '⭐',
                style: TextStyle(fontSize: 20 * scale));
          } else if (type == 'location') {
            child = Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.terracotta,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(content ?? '',
                    style: TextStyle(
                        color: Colors.white, fontSize: 8 * scale)));
          } else {
            child = const SizedBox();
          }
          widgets.add(Positioned(left: x, top: y, child: child));
        }
      }
      return widgets;
    } catch (e) {
      return [];
    }
  }

  String _getMonth(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }
}

class DrawingPath {
  List<Offset> points;
  Color color;
  double strokeWidth;

  DrawingPath(
      {required this.points,
        required this.color,
        required this.strokeWidth});

  factory DrawingPath.fromJson(Map<String, dynamic> json) => DrawingPath(
    points: (json['points'] as List)
        .map((p) => Offset(
        (p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList(),
    color: Color(json['color'] as int),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final double scale;
  DrawingPainter(this.paths, [this.scale = 0.6]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.points.isEmpty) continue;
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final drawPath = Path();
      drawPath.moveTo(
          path.points.first.dx * scale, path.points.first.dy * scale);
      for (int i = 1; i < path.points.length; i++) {
        drawPath.lineTo(
            path.points[i].dx * scale, path.points[i].dy * scale);
      }
      canvas.drawPath(drawPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4C5B0).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}