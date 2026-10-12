import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/entry_service.dart';
import '../services/journal_service.dart';
import '../models/entry.dart';
import '../models/journal.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import 'explore_screen.dart';
import 'journal_detail_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../config/api_config.dart';
import '../widgets/ad_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Harita',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary, letterSpacing: -0.6)),
                  Text('Gezdiğin ve keşfedilen yerler',
                      style: AppTheme.sansBody(
                          size: 13, color: AppTheme.textSecondary)),
                ]),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _buildTab('Haritam', 0),
                    _buildTab('Keşfet', 1),
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? const MyMapTab()
                : const ExploreMapTab(),
          ),
          const AdBanner(),
        ]),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: AppTheme.sansBody(
            size: 12, weight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}

class MyMapTab extends StatefulWidget {
  const MyMapTab({super.key});

  @override
  State<MyMapTab> createState() => _MyMapTabState();
}

class _MyMapTabState extends State<MyMapTab> {
  List<EntryWithJournal> _locations = [];
  bool _isLoading = true;
  bool _hasError = false;
  final MapController _mapController = MapController();
  double _zoom = 5;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final journals = await JournalService.getJournals();
      List<EntryWithJournal> locations = [];
      for (final journal in journals) {
        final entries = await EntryService.getEntries(journal.id);
        for (final entry in entries) {
          if (entry.lat != null && entry.lng != null) {
            locations.add(EntryWithJournal(entry: entry, journal: journal));
          }
        }
      }
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(2, 18);
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(2, 18);
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _focusLocation(LatLng point) {
    _mapController.move(point, 13);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MapSkeletonLoader();
    if (_hasError) return ErrorView(onRetry: _loadLocations);

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _locations.isNotEmpty
              ? LatLng(_locations.first.entry.lat!, _locations.first.entry.lng!)
              : const LatLng(41.0082, 28.9784),
          initialZoom: _zoom,
          onPositionChanged: (position, hasGesture) {
            if (hasGesture) _zoom = position.zoom ?? _zoom;
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.seyahood.app',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: _locations.map((item) {
              final latLng = LatLng(item.entry.lat!, item.entry.lng!);
              return Marker(
                point: latLng,
                width: 52, height: 52,
                child: GestureDetector(
                  onTap: () {
                    _focusLocation(latLng);
                    _showEntryInfo(context, item);
                  },
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC46B4E).withOpacity(0.25),
                      ),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC46B4E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),

      if (_locations.isEmpty)
        Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEADBCE)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24, offset: const Offset(0, 6))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFC46B4E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.map_rounded,
                    color: Color(0xFFC46B4E), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Henüz Rota Eklenmedi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF1C110A), letterSpacing: -0.4)),
              const SizedBox(height: 8),
              const Text(
                  'Ajandana sayfa eklerken konum eklediğinde seyahat rotan otomatik olarak burada haritalanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13,
                      color: Color(0xFF7C6A59), height: 1.5)),
            ]),
          ),
        ),

      if (_locations.isNotEmpty)
        Positioned(
          top: 14, left: 14, right: 14,
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _locations.length,
              itemBuilder: (context, idx) {
                final loc = _locations[idx];
                return GestureDetector(
                  onTap: () {
                    _focusLocation(LatLng(loc.entry.lat!, loc.entry.lng!));
                    _showEntryInfo(context, loc);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place_rounded,
                          size: 13, color: Color(0xFFC46B4E)),
                      const SizedBox(width: 4),
                      Text(loc.entry.locationName ?? 'Konum ${idx + 1}',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C110A))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),

      Positioned(
        bottom: 86, right: 16,
        child: Column(children: [
          _buildZoomButton(Icons.add_rounded, _zoomIn),
          const SizedBox(height: 8),
          _buildZoomButton(Icons.remove_rounded, _zoomOut),
        ]),
      ),

      Positioned(
        bottom: 20, left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.explore_rounded,
                color: Color(0xFFC46B4E), size: 16),
            const SizedBox(width: 6),
            Text('${_locations.length} Seyahat Noktası',
                style: const TextStyle(fontSize: 12,
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCE)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: AppTheme.navDark, size: 22),
      ),
    );
  }

  void _showEntryInfo(BuildContext context, EntryWithJournal item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(
              color: Colors.black26, blurRadius: 30, offset: Offset(0, -6))],
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 14,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                    borderRadius: BorderRadius.circular(2)),
              )),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppTheme.terracotta.withOpacity(0.3),
                        blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.entry.locationName ?? 'Konum Bilgisi',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary, letterSpacing: -0.4)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.auto_stories_rounded,
                        size: 13, color: AppTheme.terracotta),
                    const SizedBox(width: 4),
                    Text(item.journal.title,
                        style: AppTheme.sansBody(
                            size: 13, weight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ]),
                ])),
              ]),
              if (item.entry.textContent != null &&
                  item.entry.textContent!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: Text(item.entry.textContent!,
                      maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 13, color: AppTheme.textPrimary,
                          height: 1.6, fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Haritaya Dön'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) =>
                              JournalDetailScreen(journal: item.journal)));
                    },
                    icon: const Icon(Icons.auto_stories_rounded, size: 16),
                    label: const Text('Ajandaya Git'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}

class ExploreMapTab extends StatefulWidget {
  const ExploreMapTab({super.key});

  @override
  State<ExploreMapTab> createState() => _ExploreMapTabState();
}

class _ExploreMapTabState extends State<ExploreMapTab> {
  List<PublicLocation> _locations = [];
  bool _isLoading = true;
  bool _hasError = false;
  final MapController _mapController = MapController();
  double _zoom = 3;

  @override
  void initState() {
    super.initState();
    _loadPublicLocations();
  }

  Future<void> _loadPublicLocations() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/entries/public-locations'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('EXPLORE /entries/public-locations status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final locations = data.map((item) {
          final entry = Entry(
            id: item['id'],
            locationName: item['locationName'],
            lat: item['lat']?.toDouble(),
            lng: item['lng']?.toDouble(),
            textContent: item['textContent'],
            createdAt: DateTime.now(),
            photoUrls: [],
          );
          final journal = Journal(
            id: item['journalId'],
            title: item['journalTitle'],
            username: item['username'],
            visibility: 'PUBLIC',
            createdAt: DateTime.now(),
          );
          return PublicLocation(entry: entry, journal: journal);
        }).toList();
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      } else {
        debugPrint('❌ EXPLORE ERROR (body): ${response.body}');
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (e) {
      debugPrint('❌ EXPLORE ERROR: $e');
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(2, 18);
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(2, 18);
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _focusLocation(LatLng point) {
    _mapController.move(point, 13);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MapSkeletonLoader();
    if (_hasError) return ErrorView(onRetry: _loadPublicLocations);

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _locations.isNotEmpty
              ? LatLng(_locations.first.entry.lat!, _locations.first.entry.lng!)
              : const LatLng(41.0082, 28.9784),
          initialZoom: _zoom,
          onPositionChanged: (position, hasGesture) {
            if (hasGesture) _zoom = position.zoom ?? _zoom;
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.seyahood.app',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: _locations.map((item) {
              final latLng = LatLng(item.entry.lat!, item.entry.lng!);
              return Marker(
                point: latLng,
                width: 52, height: 52,
                child: GestureDetector(
                  onTap: () {
                    _focusLocation(latLng);
                    _showLocationInfo(context, item);
                  },
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.sage.withOpacity(0.25),
                      ),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.sage,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.public_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),

      if (_locations.isEmpty)
        Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEADBCE)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24, offset: const Offset(0, 6))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.sage.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.public_rounded,
                    color: AppTheme.sage, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Henüz Paylaşılan Rota Yok',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF1C110A), letterSpacing: -0.4)),
              const SizedBox(height: 8),
              const Text(
                  'Gezginlerin paylaştığı ajandalar herkese açık konumlara dönüştüğünde burada listelenecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13,
                      color: Color(0xFF7C6A59), height: 1.5)),
            ]),
          ),
        ),

      Positioned(
        bottom: 86, right: 16,
        child: Column(children: [
          _buildZoomButton(Icons.add_rounded, _zoomIn),
          const SizedBox(height: 8),
          _buildZoomButton(Icons.remove_rounded, _zoomOut),
        ]),
      ),

      Positioned(
        bottom: 20, left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.public_rounded, color: AppTheme.sage, size: 16),
            const SizedBox(width: 6),
            Text('${_locations.length} Keşif Rotası',
                style: const TextStyle(fontSize: 12,
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCE)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: AppTheme.navDark, size: 22),
      ),
    );
  }

  void _showLocationInfo(BuildContext context, PublicLocation item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(
              color: Colors.black26, blurRadius: 30, offset: Offset(0, -6))],
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 14,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: const Color(0xFFEADBCE),
                    borderRadius: BorderRadius.circular(2)),
              )),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.sage,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppTheme.sage.withOpacity(0.3),
                        blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.public_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.entry.locationName ?? 'Keşfedilen Konum',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary, letterSpacing: -0.4)),
                  const SizedBox(height: 2),
                  Text(item.journal.title,
                      style: AppTheme.sansBody(
                          size: 13, weight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text('@${item.journal.username ?? 'gezgin'}',
                      style: AppTheme.sansBody(
                          size: 12, weight: FontWeight.w700,
                          color: AppTheme.terracotta)),
                ])),
              ]),
              if (item.entry.textContent != null &&
                  item.entry.textContent!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: Text(item.entry.textContent!,
                      maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 13, color: AppTheme.textPrimary,
                          height: 1.6, fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Haritaya Dön'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) =>
                              ExploreJournalScreen(journal: item.journal)));
                    },
                    icon: const Icon(Icons.auto_stories_rounded, size: 16),
                    label: const Text('Ajandaya Git'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}

class EntryWithJournal {
  final Entry entry;
  final Journal journal;
  EntryWithJournal({required this.entry, required this.journal});
}

class PublicLocation {
  final Entry entry;
  final Journal journal;
  PublicLocation({required this.entry, required this.journal});
}