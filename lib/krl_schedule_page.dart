import 'package:flutter/material.dart';
import 'package:krl_schedule_with_gemini_ai/models/api_detail_jadwal_krl.dart';
import 'package:krl_schedule_with_gemini_ai/models/api_jadwal_krl.dart';
import 'package:krl_schedule_with_gemini_ai/services/krl_service.dart';
import 'package:krl_schedule_with_gemini_ai/services/station_name_service.dart';
import 'models/api_station_name.dart';

const double _kPadding = 16.0;
const double _kSpacing = 12.0;
final BorderRadius _kBorderRadius = BorderRadius.circular(12.0);
final BorderRadius _kCardBorderRadius = BorderRadius.circular(16.0);

class KRLSchedulePage extends StatefulWidget {
  const KRLSchedulePage({super.key});

  @override
  KRLSchedulePageState createState() => KRLSchedulePageState();
}

class KRLSchedulePageState extends State<KRLSchedulePage> {
  List<DataJadwalKrl> _schedules = [];
  bool _isLoading = false;
  Data? _selectedStartStation;
  List<Data> _stationList = [];
  List<Data> _filteredStations = [];
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _searchFocusNode;
  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = [];
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

  Future<void> _loadStations() async {
    try {
      final stationData = await loadStationsFromAssets();
      if (mounted) {
        setState(() {
          _stationList = stationData.data ?? [];

          _filteredStations = [];
        });
      }
    } catch (e) {
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

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
      if (diff.isNegative) return "Berangkat";
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
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: ListTile(
            title: Text(
              "KRLin Aja!",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
            subtitle: Text(
              "Jalan Santuy, Jadwal KRL di Tanganmu!",
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(
            Icons.train_rounded,
            color: colorScheme.onPrimary,
            size: 28,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],

              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 4.0,
        actions: [
          if (_selectedStartStation != null)
            IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
              tooltip: 'Muat Ulang Jadwal',
              onPressed:
                  _isLoading
                      ? null
                      : () => _fetchKRLJadwal(_selectedStartStation!.id ?? ''),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(theme, colorScheme),
            const SizedBox(height: _kSpacing),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildSearchResultsList(theme, colorScheme),
            ),

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

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      elevation: 3.0,
      borderRadius: _kBorderRadius,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Cari stasiun keberangkatan...',
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: _kBorderRadius,
            borderSide: BorderSide.none,
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

                      setState(() {
                        _selectedStartStation = null;
                        _schedules.clear();
                        _filteredStations.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                  : null,
        ),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildSearchResultsList(ThemeData theme, ColorScheme colorScheme) {
    if (_filteredStations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 3.0,
      borderRadius: _kBorderRadius,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: ClipRRect(
        borderRadius: _kBorderRadius,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: _kBorderRadius,
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _filteredStations.length,
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withOpacity(0.1),
                  indent: 50,
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
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedStartStation = station;
                    _schedules.clear();
                    _searchController.text = station.name ?? '';
                    _filteredStations.clear();
                  });
                  _fetchKRLJadwal(station.id ?? '');
                },

                splashColor: colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: _kBorderRadius),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(ThemeData theme, ColorScheme colorScheme) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
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

    if (_selectedStartStation == null && !isKeyboardVisible) {
      return const Center(
        key: ValueKey('initial'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
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

    if (_selectedStartStation != null && _schedules.isNotEmpty) {
      return ListView.separated(
        key: const ValueKey('schedules'),
        padding: const EdgeInsets.only(top: _kSpacing / 2, bottom: _kPadding),
        itemCount: _schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: _kSpacing),
        itemBuilder: (context, index) {
          final item = _schedules[index];

          final itemTime = item.timeEst ?? '-';
          final dest = item.dest ?? 'Tujuan Tidak Diketahui';
          final routeName = item.routeName ?? 'Rute Tidak Diketahui';
          final colorHex = item.color ?? '#808080';
          final kaName = item.kaName ?? '-';
          final kaId = item.trainId ?? '-';
          final destTime = item.destTime ?? '-';
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

    return const SizedBox.shrink(key: ValueKey('placeholder'));
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color lineColor,
    required String routeName,
    required String dest,
    required String kaName,
    required String kaId,
    required String time,
    required String destTime,
  }) {
    final timeLabel = _getTimeDifferenceLabel(time);
    final bool isUrgent = timeLabel == "Segera";
    final bool isDeparted = timeLabel == "Berangkat";

    Color timeBadgeColor =
        isUrgent
            ? Colors.orange.shade100
            : isDeparted
            ? Colors.grey.shade300
            : colorScheme.secondaryContainer.withOpacity(0.6);
    Color timeBadgeTextColor =
        isUrgent
            ? Colors.orange.shade900
            : isDeparted
            ? Colors.grey.shade700
            : colorScheme.onSecondaryContainer;

    Color timeTextColor = isDeparted ? Colors.grey : colorScheme.primary;
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: _kCardBorderRadius,

        side: BorderSide(color: lineColor, width: 4),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            isDeparted
                ? null
                : () async {
                  try {
                    final schedules = await KRLService().fetchDetailJadwal(
                      kaId,
                    );

                    if (schedules.isEmpty) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tidak ada detail jadwal tersedia.'),
                        ),
                      );
                      return;
                    }

                    detailScheduleDialog(
                      context,
                      lineColor,
                      routeName,
                      theme,
                      isDeparted,
                      colorScheme,
                      dest,
                      time,
                      timeTextColor,
                      schedules,
                    );
                  } catch (e) {
                    print("Error fetching detail: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memuat detail: $e')),
                    );
                  }
                },

        splashColor: lineColor.withOpacity(0.2),
        highlightColor: lineColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(_kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.train_sharp,
                      color: lineColor.darken(0.1),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: _kSpacing),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isDeparted
                                    ? Colors.grey.shade600
                                    : colorScheme.onSurface,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color:
                                  isDeparted
                                      ? Colors.grey.shade500
                                      : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dest,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDeparted
                                          ? Colors.grey.shade500
                                          : colorScheme.onSurfaceVariant,
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
                  const SizedBox(width: _kSpacing),

                  Text(
                    time,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: timeTextColor,
                      decoration:
                          isDeparted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _kSpacing * 1.5),

              Divider(
                color: lineColor.withOpacity(0.6),
                thickness: 1.5,
                height: 0,
              ),
              const SizedBox(height: _kSpacing * 1.5),

              _buildInfoRow(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.confirmation_number_outlined,
                label: 'Nomor KA',
                value: '$kaName ($kaId)',
                iconColor:
                    isDeparted
                        ? Colors.grey.shade500
                        : colorScheme.onSurfaceVariant.withOpacity(0.8),
                labelColor:
                    isDeparted
                        ? Colors.grey.shade500
                        : colorScheme.onSurfaceVariant.withOpacity(0.8),
                valueColor:
                    isDeparted ? Colors.grey.shade600 : colorScheme.onSurface,
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color:
                        isDeparted
                            ? Colors.grey.shade500
                            : colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      "Status:",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isDeparted
                                ? Colors.grey.shade500
                                : colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  Chip(
                    avatar:
                        isUrgent
                            ? Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: timeBadgeTextColor,
                            )
                            : isDeparted
                            ? Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: timeBadgeTextColor,
                            )
                            : null,
                    label: Text(timeLabel),
                    labelStyle: TextStyle(
                      color: timeBadgeTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: timeBadgeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    elevation:
                        isUrgent
                            ? 2.0
                            : isDeparted
                            ? 0.0
                            : 0.0,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              _buildInfoRow(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.access_time_outlined,
                label: "Tiba",
                value: destTime,
                valueColor:
                    isDeparted ? Colors.grey.shade600 : colorScheme.onSurface,
                iconColor:
                    isDeparted
                        ? Colors.grey.shade500
                        : colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> detailScheduleDialog(
    BuildContext context,
    Color lineColor,
    String routeName,
    ThemeData theme,
    bool isDeparted,
    ColorScheme colorScheme,
    String dest,
    String time,
    Color timeTextColor,
    List<DataDetailJadwalKrl> schedules,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      lineColor.withOpacity(0.3),
                      lineColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.train_sharp,
                  color: lineColor.darken(0.1),
                  size: 20,
                ),
              ),
              const SizedBox(width: _kSpacing),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDeparted
                                ? Colors.grey.shade600
                                : colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color:
                              isDeparted
                                  ? Colors.grey.shade500
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dest,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isDeparted
                                      ? Colors.grey.shade500
                                      : colorScheme.onSurfaceVariant,
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
              const SizedBox(width: _kSpacing),

              Text(
                time,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: timeTextColor,
                  decoration: isDeparted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey,
                ),
              ),
            ],
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentPadding: const EdgeInsets.all(_kPadding),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    color: lineColor.withOpacity(0.6),
                    thickness: 1.5,
                    height: 0,
                  ),
                  const SizedBox(height: _kSpacing * 1.5),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: schedules.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return ListTile(
                          title: Text(schedule.stationName ?? '-'),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (schedule.transitStation == true)
                                    ...schedule.transit!.map((transit) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: Chip(
                                          label: Icon(
                                            Icons.train_sharp,
                                            size: 20,
                                            color: _hexToColor(transit),
                                          ),
                                          backgroundColor: _hexToColor(
                                            transit,
                                          ).withOpacity(0.1),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 4,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide.none,
                                        ),
                                      );
                                    }).toList()
                                  else
                                    const Icon(
                                      Icons.train_outlined,
                                      size: 20,
                                      color: Colors.transparent,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(schedule.timeEst ?? '-'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FocusScope.of(context).unfocus();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
      barrierDismissible: true,
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? labelColor,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(
                "$label:",
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      labelColor ??
                      colorScheme.onSurfaceVariant.withOpacity(0.8),
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
              color: valueColor ?? colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
