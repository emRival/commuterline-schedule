import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:krl_schedule_with_gemini_ai/services/krl_service.dart';
import 'package:krl_schedule_with_gemini_ai/services/station_name_service.dart';
import 'dart:convert';
import 'models/api_station_name.dart';

// --- Konstanta untuk Styling ---
const double _kPadding = 16.0;
const double _kSpacing = 12.0;
final BorderRadius _kBorderRadius = BorderRadius.circular(12.0);
final BorderRadius _kCardBorderRadius = BorderRadius.circular(16.0);

class KRLSchedulePage extends StatefulWidget {
  @override
  _KRLSchedulePageState createState() => _KRLSchedulePageState();
}

class _KRLSchedulePageState extends State<KRLSchedulePage> {
  List<dynamic> _schedules = [];
  bool _isLoading = false;
  Data? _selectedStartStation;
  List<Data> _stationList = [];
  List<Data> _filteredStations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Fungsi Pencarian Stasiun ---
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = []; // Kosongkan jika query kosong
      } else {
        _filteredStations =
            _stationList.where((station) {
              final name = station.name?.toLowerCase() ?? '';
              final id = station.id?.toLowerCase() ?? '';
              return name.contains(query) || id.contains(query);
            }).toList();
      }
    });
  }

  // --- Fungsi Load Stasiun dari Assets ---
  Future<void> _loadStations() async {
    try {
      // Ganti dengan implementasi loadStationsFromAssets Anda
      final stationData = await loadStationsFromAssets();
      if (mounted) {
        setState(() {
          _stationList = stationData.data ?? [];
          // Awalnya tidak menampilkan hasil filter sampai user mengetik
          _filteredStations = [];
        });
      }
    } catch (e) {
      print('Gagal load stasiun: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data stasiun: $e')),
        );
      }
    }
  }

  Future<void> _fetchKRLJadwal(String stationCode) async {
    if (stationCode.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final schedules = await KRLService().fetchJadwal(stationCode);
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // --- Helper Konversi Hex ke Color ---
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if missing
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback color
    }
  }

  // --- Helper Mendapatkan Label Perbedaan Waktu ---
  String _getTimeDifferenceLabel(String time) {
    try {
      final now = DateTime.now();
      final parts = time.split(':');
      if (parts.length < 2) return "-";

      final targetHour = int.tryParse(parts[0]);
      final targetMinute = int.tryParse(parts[1]);
      if (targetHour == null || targetMinute == null) return "-";

      var targetTime = DateTime(
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );

      final diff = targetTime.difference(now);

      if (diff.isNegative) return "Berangkat"; // Atau "Sudah Lewat"
      if (diff.inMinutes < 1) return "Segera";
      if (diff.inMinutes < 60) return "${diff.inMinutes} menit lagi";

      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes == 0) {
        return "$hours jam lagi";
      } else {
        return "$hours jam $minutes menit lagi";
      }
    } catch (e) {
      print("Error parsing time diff: $e");
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // --- AppBar dengan Gradient dan Style ---
      appBar: AppBar(
        // centerTitle: true, // Hapus atau komen ini agar judul rata kiri (lebih umum di UI modern)
        titleSpacing:
            0, // Set titleSpacing ke 0 agar judul lebih dekat ke leading icon
        title: Padding(
          padding: const EdgeInsets.only(
            left: 0.0,
          ), // Padding kiri di sini bisa disesuaikan jika leading dihilangkan atau diubah
          child: Text(
            "Jadwal KRL Commuter Line", // Atau bisa disingkat "Jadwal KRL" jika terlalu panjang
            style: theme.textTheme.titleLarge?.copyWith(
              // Menggunakan ukuran font yang lebih besar dan konsisten
              fontWeight: FontWeight.bold,
              color:
                  colorScheme
                      .onPrimary, // Warna teks kontras dg background AppBar
            ),
          ),
        ),
        leading: Padding(
          // Tambahkan ikon KRL di sebelah kiri (leading)
          padding: const EdgeInsets.only(
            left: 16.0,
          ), // Beri padding kiri agar tidak terlalu mepet
          child: Icon(
            Icons
                .train_rounded, // Ikon kereta yang mungkin lebih estetik (pilih yang Anda suka)
            color: colorScheme.onPrimary, // Warna ikon kontras
            size: 28, // Ukuran ikon yang pas
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(
                  0.8,
                ), // Warna kedua sedikit transparan
              ], // Gunakan warna tema
              // Arah gradient bisa diubah untuk variasi visual
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              // begin: Alignment.topCenter,
              // end: Alignment.bottomCenter,
            ),
            // Anda bisa tambahkan gambar latar belakang KRL di sini jika mau, tapi akan jadi kompleks
            // image: DecorationImage(...)
          ),
        ),
        elevation: 4.0, // Tingkatkan shadow sedikit agar AppBar lebih menonjol
        actions: [
          // Tombol refresh (opsional)
          if (_selectedStartStation != null)
            IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
              tooltip: 'Muat Ulang Jadwal',
              onPressed:
                  _isLoading
                      ? null // Nonaktifkan tombol saat loading
                      : () => _fetchKRLJadwal(_selectedStartStation!.id ?? ''),
            ),
          const SizedBox(width: 8), // Tambahkan sedikit spasi di ujung kanan
        ],
        // backgroundColor: Colors.transparent, // Set transparent agar gradient terlihat
      ),
      body: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Search Bar dengan Style ---
            _buildSearchBar(theme, colorScheme),

            const SizedBox(height: _kSpacing),

            // --- Daftar Hasil Pencarian (Animated) ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildSearchResultsList(theme, colorScheme),
            ),

            // Tampilkan nama stasiun terpilih jika ada

            // --- Konten Utama (Loading, Empty, atau List Jadwal) ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildContentArea(theme, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Search Bar ---
  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      elevation: 3.0, // Shadow halus
      borderRadius: _kBorderRadius,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari stasiun keberangkatan...',
          filled: true,
          fillColor: colorScheme.surface, // Warna background sesuai tema
          border: OutlineInputBorder(
            borderRadius: _kBorderRadius,
            borderSide: BorderSide.none, // Hapus border
          ),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: _kPadding,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      // Reset state jika diperlukan saat clear
                      setState(() {
                        _selectedStartStation = null;
                        _schedules.clear();
                        _filteredStations.clear();
                      });
                      FocusScope.of(context).unfocus(); // Tutup keyboard
                    },
                  )
                  : null,
        ),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  // --- Widget: Daftar Hasil Pencarian Stasiun ---
  Widget _buildSearchResultsList(ThemeData theme, ColorScheme colorScheme) {
    if (_filteredStations.isEmpty) {
      return const SizedBox.shrink(); // Jangan tampilkan apapun jika tidak ada filter
    }

    // Gunakan Material + ClipRRect untuk efek visual yang lebih baik
    return Material(
      elevation: 3.0,
      borderRadius: _kBorderRadius,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: ClipRRect(
        borderRadius: _kBorderRadius,
        child: Container(
          // Batasi tinggi list hasil pencarian
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                0.3, // Max 30% tinggi layar
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: _kBorderRadius,
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero, // Hapus padding default ListView
            shrinkWrap: true, // Agar tinggi list sesuai konten
            itemCount: _filteredStations.length,
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withOpacity(0.1),
                  indent: 50, // Beri indentasi pada divider
                ),
            itemBuilder: (context, index) {
              final station = _filteredStations[index];
              return ListTile(
                leading: Icon(
                  Icons.directions_transit_filled,
                  color: colorScheme.primary,
                ),
                title: Text(
                  station.name ?? 'Tanpa Nama',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  station.id ?? 'Tanpa ID',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  FocusScope.of(context).unfocus(); // Tutup keyboard
                  setState(() {
                    _selectedStartStation = station;
                    _schedules.clear(); // Kosongkan jadwal lama
                    _searchController.text =
                        station.name ?? ''; // Update teks search bar
                    _filteredStations.clear(); // Sembunyikan daftar hasil
                  });
                  _fetchKRLJadwal(station.id ?? ''); // Ambil jadwal baru
                },
                // Tambahkan efek visual saat ditekan
                splashColor: colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: _kBorderRadius),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Widget: Area Konten Utama (Loading/Empty/List Jadwal) ---
  Widget _buildContentArea(ThemeData theme, ColorScheme colorScheme) {
    // Dapatkan status visibilitas keyboard
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // --- Loading State ---
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'), // Key untuk AnimatedSwitcher
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: _kPadding),
            Text('Memuat jadwal...'),
          ],
        ),
      );
    }

    // --- Initial State (Tampilkan HANYA jika tidak ada stasiun terpilih DAN keyboard TIDAK aktif) ---
    if (_selectedStartStation == null && !isKeyboardVisible) {
      // MODIFIKASI DI SINI
      return const Center(
        key: ValueKey('initial'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gunakan ikon yang lebih relevan mungkin? Misal directions_railway atau search_off
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey,
            ), // Contoh ikon lain
            SizedBox(height: _kPadding),
            Text(
              'Silakan cari dan pilih stasiun\nkeberangkatan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- Empty State (Sudah memilih stasiun, tapi tidak ada jadwal) ---
    // Kondisi ini tidak perlu cek keyboard, tetap tampilkan jika jadwal kosong
    if (_selectedStartStation != null && _schedules.isEmpty) {
      return const Center(
        key: ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train_outlined, size: 60, color: Colors.grey),
            SizedBox(height: _kPadding),
            Text(
              'Tidak ada jadwal tersedia\nuntuk stasiun ini saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- List Jadwal ---
    // Kondisi ini juga tidak perlu cek keyboard
    if (_selectedStartStation != null && _schedules.isNotEmpty) {
      return ListView.separated(
        key: const ValueKey('schedules'), // Key untuk AnimatedSwitcher
        padding: const EdgeInsets.only(
          top: _kSpacing / 2,
          bottom: _kPadding,
        ), // Beri padding bawah
        itemCount: _schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: _kSpacing),
        itemBuilder: (context, index) {
          final item = _schedules[index];

          // Ekstraksi data (kode sama seperti sebelumnya)
          final itemTime = item['time_est'] as String? ?? '-';
          final dest = item['dest'] as String? ?? 'Tujuan Tidak Diketahui';
          final routeName =
              item['route_name'] as String? ?? 'Rute Tidak Diketahui';
          final colorHex = item['color'] as String? ?? '#808080';
          final kaName = item['ka_name'] as String? ?? '-';
          final kaId = item['train_id'] as String? ?? '-';
          final destTime = item['dest_time'] as String? ?? '-';

          return _buildScheduleCard(
            context: context,
            theme: theme,
            colorScheme: colorScheme,
            lineColor: _hexToColor(colorHex),
            routeName: routeName,
            dest: dest,
            kaName: kaName,
            kaId: kaId,
            time: itemTime,
            destTime: destTime,
          );
        },
      );
    }

    // --- Fallback: Tampilkan widget kosong jika kondisi lain tidak terpenuhi ---
    // (Ini akan menangani kasus _selectedStartStation == null && isKeyboardVisible)
    return const SizedBox.shrink(key: ValueKey('placeholder')); // Widget kosong
  }

  // --- Widget: Kartu Jadwal Individual (Revisi) ---
  Widget _buildScheduleCard({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color lineColor, // Warna jalur KRL dari API
    required String routeName,
    required String dest,
    required String kaName,
    required String kaId,
    required String time,
    required String destTime,
  }) {
    final timeLabel = _getTimeDifferenceLabel(time);
    final bool isUrgent = timeLabel == "Segera";
    final bool isDeparted =
        timeLabel == "Berangkat"; // Tambahan untuk status sudah berangkat

    // Tentukan warna aksen berdasarkan status waktu
    Color timeBadgeColor =
        isUrgent
            ? Colors
                .orange
                .shade100 // Latar belakang oranye untuk Segera
            : isDeparted
            ? Colors
                .grey
                .shade300 // Latar belakang abu-abu untuk Berangkat
            : colorScheme.secondaryContainer.withOpacity(
              0.6,
            ); // Warna tema netral

    Color timeBadgeTextColor =
        isUrgent
            ? Colors
                .orange
                .shade900 // Teks gelap untuk Segera
            : isDeparted
            ? Colors
                .grey
                .shade700 // Teks gelap untuk Berangkat
            : colorScheme.onSecondaryContainer; // Warna teks tema

    // Tentukan warna teks utama untuk jam, bisa berbeda jika sudah berangkat
    Color timeTextColor = isDeparted ? Colors.grey : colorScheme.primary;

    return Card(
      elevation: 4.0, // Beri sedikit shadow lebih terangkat
      shape: RoundedRectangleBorder(
        borderRadius: _kCardBorderRadius,
        // Tambahkan border samping dengan warna rute (lineColor) yang lebih tebal
        side: BorderSide(
          color: lineColor,
          width: 4,
        ), // Border samping lebih tegas
      ),
      margin:
          EdgeInsets
              .zero, // Atur margin di luar widget ini jika perlu jarak antar kartu
      clipBehavior:
          Clip.antiAlias, // Memastikan konten tidak melewati border radius
      child: InkWell(
        onTap:
            isDeparted
                ? null
                : () {
                  // Nonaktifkan onTap jika sudah berangkat
                  print(
                    "Tapped schedule: KA $kaName ($kaId) to $dest at $time",
                  );
                  // Tambahkan navigasi atau aksi lain di sini
                },
        splashColor: lineColor.withOpacity(0.2),
        highlightColor: lineColor.withOpacity(0.1),
        child: Padding(
          // Beri padding horizontal konsisten, border sudah di card shape
          padding: const EdgeInsets.all(_kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Baris Header (Ikon, Rute, Tujuan, Waktu) ---
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center vertikal
                children: [
                  // Indikator Warna Jalur & Ikon (Lebih Menonjol)
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      // Gunakan gradient lembut dari warna rute
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(
                            0.3,
                          ), // Warna rute lebih transparan
                          lineColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        12.0,
                      ), // Sedikit lebih bulat dari card
                    ),
                    child: Icon(
                      Icons.train_sharp, // Ikon kereta
                      color: lineColor.darken(
                        0.1,
                      ), // Sedikit lebih gelap dari warna rute agar kontras
                      size: 30, // Icon lebih besar
                    ),
                  ),
                  const SizedBox(width: _kSpacing), // Spasi setelah ikon
                  // Info Rute dan Tujuan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeName, // Nama Rute lebih besar dan tebal
                          style: theme.textTheme.titleMedium?.copyWith(
                            // Ukuran lebih besar (TitleLarge)
                            fontWeight: FontWeight.bold, // Bold
                            color:
                                isDeparted
                                    ? Colors.grey.shade600
                                    : colorScheme
                                        .onSurface, // Warna abu jika berangkat
                            height: 1.2, // Sedikit spasi antar baris jika wrap
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4), // Spasi kecil
                        Row(
                          // Ikon kecil untuk tujuan
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color:
                                  isDeparted
                                      ? Colors.grey.shade500
                                      : colorScheme.onSurfaceVariant,
                            ), // Warna abu jika berangkat
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dest, // Tujuan font lebih kecil
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDeparted
                                          ? Colors.grey.shade500
                                          : colorScheme
                                              .onSurfaceVariant, // Warna abu jika berangkat
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _kSpacing), // Spasi sebelum jam
                  // Jam Keberangkatan (Sangat Menonjol)
                  Text(
                    time,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      // Ukuran lebih besar (HeadlineMedium)
                      fontWeight: FontWeight.w900, // Sangat tebal
                      color: timeTextColor, // Warna jam sesuai status
                      decoration:
                          isDeparted
                              ? TextDecoration.lineThrough
                              : null, // Coret jika berangkat
                      decorationColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: _kSpacing * 1.5,
              ), // Spasi sebelum divider lebih besar
              // --- Divider dengan Warna Rute ---
              Divider(
                color: lineColor.withOpacity(
                  0.6,
                ), // Warna divider dari lineColor, sedikit lebih solid
                thickness: 1.5, // Divider sedikit lebih tebal
                height:
                    0, // Height 0 karena spasi sudah diatur di atas dan bawah
              ),

              const SizedBox(
                height: _kSpacing * 1.5,
              ), // Spasi setelah divider lebih besar
              // --- Baris Info Detail (Nomor KA) ---
              _buildInfoRow(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.confirmation_number_outlined,
                label: 'Nomor KA',
                value: '$kaName ($kaId)',
                iconColor:
                    isDeparted
                        ? Colors.grey.shade500
                        : colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ), // Warna abu jika berangkat
                labelColor:
                    isDeparted
                        ? Colors.grey.shade500
                        : colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ), // Warna abu jika berangkat
                valueColor:
                    isDeparted
                        ? Colors.grey.shade600
                        : colorScheme.onSurface, // Warna abu jika berangkat
              ),
              const SizedBox(height: 8), // Spasi antar detail
              // --- Baris Info Estimasi Waktu (Menggunakan Chip) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule, // Ikon jam untuk status waktu
                    size: 18,
                    color:
                        isDeparted
                            ? Colors.grey.shade500
                            : colorScheme.onSurfaceVariant.withOpacity(
                              0.8,
                            ), // Warna abu jika berangkat
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70, // Lebar label tetap
                    child: Text(
                      "Status:", // Ganti label jadi Status?
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isDeparted
                                ? Colors.grey.shade500
                                : colorScheme.onSurfaceVariant.withOpacity(
                                  0.8,
                                ), // Warna abu jika berangkat
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Gunakan Chip untuk visual yang lebih baik
                  Chip(
                    avatar:
                        isUrgent
                            ? Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: timeBadgeTextColor,
                            ) // Ikon outline agar tidak terlalu padat
                            : isDeparted
                            ? Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: timeBadgeTextColor,
                            ) // Ikon outline
                            : null, // Icon sesuai status
                    label: Text(timeLabel),
                    labelStyle: TextStyle(
                      color: timeBadgeTextColor, // Warna teks sesuai status
                      fontWeight: FontWeight.w600, // Semi-bold
                      fontSize: 12,
                    ),
                    backgroundColor:
                        timeBadgeColor, // Warna latar sesuai status
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ), // Padding Chip
                    visualDensity: VisualDensity.compact, // Chip lebih ringkas
                    side: BorderSide.none, // Hapus border default chip
                    elevation:
                        isUrgent
                            ? 2.0
                            : isDeparted
                            ? 0.0
                            : 0.0, // Sedikit shadow jika Segera
                    // Jika status "Berangkat", bisa tambahkan visual lain seperti opacity pada seluruh kartu
                  ),
                ],
              ),
              // Tambahkan sedikit spasi di bagian bawah jika diperlukan
              const SizedBox(height: 8),
              _buildInfoRow(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.access_time_outlined,

                label: "Tiba",
                value: destTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: Baris Info Detail dalam Kartu (Revisi Minor) ---
  // Ditambahkan parameter warna untuk fleksibilitas status berangkat
  Widget _buildInfoRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor, // Warna ikon bisa di-override
    Color? labelColor, // Warna label bisa di-override
    Color? valueColor, // Warna value bisa di-override
    FontWeight? valueWeight,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align start untuk teks panjang
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18, // Ukuran ikon detail
              color:
                  iconColor ??
                  colorScheme.onSurfaceVariant.withOpacity(
                    0.8,
                  ), // Gunakan warna dari parameter atau default
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70, // Lebar tetap untuk label agar rata kiri
              child: Text(
                "$label:",
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      labelColor ??
                      colorScheme.onSurfaceVariant.withOpacity(
                        0.8,
                      ), // Gunakan warna dari parameter atau default
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: valueWeight ?? FontWeight.w500,
              color:
                  valueColor ??
                  colorScheme
                      .onSurface, // Gunakan warna dari parameter atau default
              height: 1.3, // Sedikit ruang jika teks value panjang dan wrap
            ),
          ),
        ),
      ],
    );
  }

  // Extension helper untuk menggelapkan warna, tambahkan ini di luar class widget
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
