import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  List<LogEntry> _logs = [];
  LogEntry? _realtimeData;
  bool _isLoading = true;
  bool _hasError = false;

  // Warna sesuai design
  final Color _darkGreen = const Color(0xFF2D5016);
  final Color _red = const Color(0xFFB71C1C);
  final Color _blue = const Color(0xFF1565C0);
  final Color _orange = const Color(0xFFF57C00);
  final Color _teal = const Color(0xFF00695C);
  final Color _lightGreen = const Color(0xFF4CAF50);
  final Color _gray = const Color(0xFF757575);
  
  @override
  void initState() {
    super.initState();
    _initializeRealtimeListener();
  }

  void _initializeRealtimeListener() {
    // Listen untuk current_data (realtime)
    _databaseRef.child('current_data').onValue.listen((DatabaseEvent event) {
      _handleRealtimeData(event.snapshot.value);
    });

    // Load history data
    _loadHistoryData();
  }

  void _handleRealtimeData(dynamic data) {
    if (data != null && data is Map) {
      setState(() {
        _realtimeData = _createLogEntry('realtime', data, DateTime.now().millisecondsSinceEpoch);
      });
    }
  }

  void _loadHistoryData() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _databaseRef.child('history_data')
      .orderByKey()
      .limitToLast(100)
      .once()
      .then((DatabaseEvent event) {
      try {
        final data = event.snapshot.value;
        final List<LogEntry> logs = [];

        if (data != null && data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              final int timestamp = _parseTimestamp(value, key.toString());
              logs.add(_createLogEntry(key.toString(), value, timestamp));
            }
          });
        }

        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      } catch (e) {
        print('❌ Error loading history data: $e');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });
  }

  // PERBAIKAN: Fungsi parsing timestamp yang lebih baik
  int _parseTimestamp(Map<dynamic, dynamic> data, String key) {
    print('🔍 Parsing timestamp for key: $key');
    
    // 1. Coba dari timestamp field langsung (dalam milliseconds)
    if (data['timestamp'] != null) {
      print('   📊 Raw timestamp value: ${data['timestamp']} (type: ${data['timestamp'].runtimeType})');
      
      final ts = data['timestamp'];
      if (ts is int) {
        print('   ✅ Using int timestamp: $ts');
        
        // PERBAIKAN: Validasi timestamp untuk tahun 2025
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        final year = date.year;
        print('   📅 Date from timestamp: ${date.toString()} (Year: $year)');
        
        // Jika tahun kurang dari 2025, sesuaikan ke 2025
        if (year < 2025) {
          print('   ⚠ Year $year < 2025, adjusting to 2025');
          // Tambahkan jumlah milidetik untuk mencapai tahun 2025
          final newDate = DateTime(2025, date.month, date.day, date.hour, date.minute, date.second);
          final adjustedTs = newDate.millisecondsSinceEpoch;
          print('   🔄 Adjusted timestamp: $adjustedTs (Date: ${newDate.toString()})');
          return adjustedTs;
        }
        
        return ts;
      }
      
      if (ts is String) {
        final parsed = int.tryParse(ts);
        if (parsed != null) {
          print('   ✅ Using string timestamp: $parsed');
          
          // PERBAIKAN: Validasi timestamp untuk tahun 2025
          final date = DateTime.fromMillisecondsSinceEpoch(parsed);
          final year = date.year;
          print('   📅 Date from timestamp: ${date.toString()} (Year: $year)');
          
          // Jika tahun kurang dari 2025, sesuaikan ke 2025
          if (year < 2025) {
            print('   ⚠ Year $year < 2025, adjusting to 2025');
            final newDate = DateTime(2025, date.month, date.day, date.hour, date.minute, date.second);
            final adjustedTs = newDate.millisecondsSinceEpoch;
            print('   🔄 Adjusted timestamp: $adjustedTs (Date: ${newDate.toString()})');
            return adjustedTs;
          }
          
          return parsed;
        }
      }
    }

    // 2. Coba dari datetime field (format ISO 8601 atau custom)
    if (data['datetime'] != null) {
      final dateString = data['datetime'].toString();
      print('   📅 Parsing datetime: $dateString');
      
      DateTime? dateTime;
      
      // Coba parse sebagai ISO 8601
      dateTime = DateTime.tryParse(dateString);
      
      // Jika gagal, coba format custom: "2025-11-28 20:56:20"
      if (dateTime == null && dateString.contains(' ') && dateString.contains('-') && dateString.contains(':')) {
        try {
          final parts = dateString.split(' ');
          if (parts.length == 2) {
            final dateParts = parts[0].split('-');
            final timeParts = parts[1].split(':');
            
            if (dateParts.length == 3 && timeParts.length == 3) {
              final year = int.tryParse(dateParts[0]) ?? 2025;
              final month = int.tryParse(dateParts[1]) ?? 11;
              final day = int.tryParse(dateParts[2]) ?? 28;
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              final second = int.tryParse(timeParts[2]) ?? 0;
              
              // PERBAIKAN: Pastikan tahun 2025
              final adjustedYear = year < 2025 ? 2025 : year;
              
              dateTime = DateTime(adjustedYear, month, day, hour, minute, second);
              print('   ✅ Parsed custom datetime: ${dateTime.toString()}');
            }
          }
        } catch (e) {
          print('   ❌ Error parsing custom datetime: $e');
        }
      }
      
      if (dateTime != null) {
        print('   ✅ Using datetime: ${dateTime.toString()}');
        return dateTime.millisecondsSinceEpoch;
      }
    }

    // 3. Parse dari key (format: data_1701116800000_12345)
    final regex = RegExp(r'(\d{10,})');
    final match = regex.firstMatch(key);
    if (match != null) {
      final millisStr = match.group(1)!;
      print('   🔑 Parsing from key: $millisStr');
      
      int? millis = int.tryParse(millisStr);
      if (millis != null) {
        // Konversi detik ke milidetik jika perlu
        if (millis < 100000000000) {
          millis = millis * 1000;
          print('   🔄 Converted seconds to milliseconds: $millis');
        }
        
        // PERBAIKAN: Validasi tahun 2025
        final date = DateTime.fromMillisecondsSinceEpoch(millis);
        final year = date.year;
        print('   📅 Date from key: ${date.toString()} (Year: $year)');
        
        // Jika tahun kurang dari 2025, sesuaikan ke 2025
        if (year < 2025) {
          print('   ⚠ Year $year < 2025, adjusting to 2025');
          final newDate = DateTime(2025, date.month, date.day, date.hour, date.minute, date.second);
          final adjustedMillis = newDate.millisecondsSinceEpoch;
          print('   🔄 Adjusted timestamp: $adjustedMillis (Date: ${newDate.toString()})');
          return adjustedMillis;
        }
        
        return millis;
      }
    }

    // 4. Fallback: Waktu sekarang dengan tahun 2025
    print('   ⚠ No valid timestamp found, using current time adjusted to 2025');
    final now = DateTime.now();
    final adjustedNow = DateTime(2025, now.month, now.day, now.hour, now.minute, now.second);
    print('   🕒 Fallback to: ${adjustedNow.toString()}');
    
    return adjustedNow.millisecondsSinceEpoch;
  }

  LogEntry _createLogEntry(String id, Map<dynamic, dynamic> data, int timestamp) {
    print('📝 Creating log entry: $id, timestamp: $timestamp');
    
    // PERBAIKAN: Parse tanggal untuk display yang benar
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final year = date.year;
    print('   📅 Parsed date: ${date.toString()} (Year: $year)');
    
    return LogEntry(
      id: id,
      timestamp: timestamp,
      temperature: _toDouble(data['suhu']),
      humidity: _toDouble(data['kelembaban_udara']),
      soilMoisture: _toDouble(data['kelembaban_tanah']),
      brightness: _toDouble(data['kecerahan']),
      soilCategory: data['kategori_tanah']?.toString(),
      operationMode: data['mode_operasi']?.toString() ?? 'AUTO',
      pumpStatus: data['status_pompa']?.toString() ?? 'OFF',
      plantStage: data['tahapan_tanaman']?.toString() ?? 'BIBIT',
      plantAge: data['umur_tanaman'] != null ? int.tryParse(data['umur_tanaman'].toString()) : 1,
      timeOfDay: data['waktu']?.toString(),
      datetime: data['datetime']?.toString(),
      // PERBAIKAN: Tambahkan tanggal yang sudah diformat dengan benar
      formattedDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _refreshData() {
    _loadHistoryData();
  }

  // Hitung statistik
  int get _totalData => _logs.length;
  int get _drySoilCount => _logs.where((log) => 
    log.soilCategory == 'SANGAT KERING' || log.soilCategory == 'KERING').length;
  int get _pumpOnCount => _logs.where((log) => log.pumpStatus == 'ON').length;
  int get _autoModeCount => _logs.where((log) => log.operationMode == 'AUTO').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hanya tombol refresh di pojok kanan
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _refreshData,
                  icon: Icon(Icons.refresh, color: _darkGreen),
                ),
              ),
              const SizedBox(height: 8),
              
              // Realtime Data Card - DIPERBAIKI
              if (_realtimeData != null) _buildRealtimeCard(),
              const SizedBox(height: 16),

              // Summary Statistics Grid
              _buildSummaryGrid(),
              const SizedBox(height: 16),

              // History List
              Text(
                'Riwayat Monitoring',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                        ? _buildErrorState()
                        : _logs.isEmpty
                            ? _buildEmptyState()
                            : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealtimeCard() {
    final log = _realtimeData!;
    // PERBAIKAN: Gunakan formattedDate jika ada, jika tidak parse dari timestamp
    final displayDateTime = log.formattedDate ?? 
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(log.timestamp));
    
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SmartFarm Tomat - REALTIME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // PERBAIKAN: Tampilkan tahun 2025 dengan jelas
              Text(
                '2025/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // PERBAIKAN: Tampilkan informasi seperti ESP32
          Text(
            '🌱 Sistem Siap | ${log.plantStage} | Hari ke-${log.plantAge ?? 1}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Waktu: $displayDateTime',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          
          // Data Real-Time section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Data Real-Time:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRealtimeDataItem('${log.temperature?.toStringAsFixed(1) ?? '-'}°C'),
                      _buildRealtimeDataItem('${log.humidity?.toStringAsFixed(1) ?? '-'}%'),
                      _buildRealtimeDataItem('${log.soilMoisture?.toStringAsFixed(1) ?? '-'}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      log.pumpStatus == 'ON' ? Icons.water_drop : Icons.water_drop_outlined,
                      color: log.pumpStatus == 'ON' ? Colors.greenAccent : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pompa: ${log.pumpStatus}',
                      style: TextStyle(
                        color: log.pumpStatus == 'ON' ? Colors.greenAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      log.operationMode == 'AUTO' ? Icons.auto_awesome : Icons.settings,
                      color: log.operationMode == 'AUTO' ? Colors.blueAccent : Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mode: ${log.operationMode}',
                      style: TextStyle(
                        color: log.operationMode == 'AUTO' ? Colors.blueAccent : Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeFormat.format(date),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeDataItem(String value) {
    return Text(
      value,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Total Data', _totalData.toString(), Icons.list, _darkGreen),
          _buildSummaryItem('Pompa ON', _pumpOnCount.toString(), Icons.water_drop, _blue),
          _buildSummaryItem('Tanah Kering', _drySoilCount.toString(), Icons.grass, _orange),
          _buildSummaryItem('Auto Mode', _autoModeCount.toString(), Icons.smart_toy, _teal),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: _gray,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      itemCount: _logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildHistoryItem(_logs[index]);
      },
    );
  }

  Widget _buildHistoryItem(LogEntry log) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeFormat = DateFormat('HH:mm:ss');
    
    // PERBAIKAN: Gunakan formattedDate jika ada
    final displayDate = log.formattedDate ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    
    // Format untuk header
    final headerDateFormat = DateFormat('yyyy/MM/dd');
    final headerDate = headerDateFormat.format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Mode dan waktu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: log.operationMode == 'AUTO' ? _blue.withOpacity(0.1) : _orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Mode: ${log.operationMode}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: log.operationMode == 'AUTO' ? _blue : _orange,
                  ),
                ),
              ),
              if (log.timeOfDay != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.timeOfDay!,
                    style: TextStyle(
                      fontSize: 10,
                      color: _gray,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // PERBAIKAN: Tampilkan tanggal dengan tahun 2025
              Text(
                headerDate,
                style: TextStyle(
                  color: _gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // PERBAIKAN: Tambahkan informasi tanaman dan waktu lengkap
          if (log.plantStage != null)
            Text(
              '🌱 ${log.plantStage} | Hari ke-${log.plantAge ?? 1}',
              style: TextStyle(
                fontSize: 11,
                color: _darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '📅 $displayDate',
            style: TextStyle(
              fontSize: 10,
              color: _gray,
            ),
          ),
          const SizedBox(height: 12),
          
          // Data sensor dalam row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSensorItem('🌡️', '${log.temperature?.toStringAsFixed(1) ?? '-'}°C', _red),
              _buildSensorItem('💧', '${log.humidity?.toStringAsFixed(0) ?? '-'}%', _blue),
              _buildSensorItem('🌱', '${log.soilMoisture?.toStringAsFixed(0) ?? '-'}%', _darkGreen),
              _buildSensorItem('💡', '${log.brightness?.toStringAsFixed(1) ?? '-'}%', _orange),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status bar
          Row(
            children: [
              _buildStatusChip(
                'Pompa: ${log.pumpStatus}',
                log.pumpStatus == 'ON',
                log.pumpStatus == 'ON' ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              if (log.soilCategory != null) 
                _buildStatusChip(
                  'Tanah: ${log.soilCategory}',
                  false,
                  _getSoilColor(log.soilCategory!),
                ),
              const Spacer(),
              Text(
                timeFormat.format(date),
                style: TextStyle(
                  color: _gray,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(String emoji, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getSoilColor(String soilCategory) {
    switch (soilCategory) {
      case 'SANGAT KERING':
        return _red;
      case 'KERING':
        return _orange;
      case 'LEMBAB':
        return _lightGreen;
      case 'BASAH':
        return _blue;
      default:
        return _gray;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _darkGreen),
          const SizedBox(height: 16),
          Text('Memuat data...', style: TextStyle(color: _darkGreen)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: _red),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: TextStyle(color: _red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Belum ada data', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class LogEntry {
  final String id;
  final int timestamp;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? brightness;
  final String? soilCategory;
  final String operationMode;
  final String pumpStatus;
  final String plantStage;
  final int? plantAge; // Tambahkan plantAge
  final String? timeOfDay;
  final String? datetime;
  final String? formattedDate; // PERBAIKAN: Tambahkan field untuk tanggal yang sudah diformat

  LogEntry({
    required this.id,
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.brightness,
    this.soilCategory,
    required this.operationMode,
    required this.pumpStatus,
    required this.plantStage,
    this.plantAge,
    this.timeOfDay,
    this.datetime,
    this.formattedDate, 
  });
}