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
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    print('🔄 Loading logs from Firebase...');
    
    // PERBAIKAN: Mengambil data berdasarkan key (millis) bukan berdasarkan timestamp field
    _databaseRef.child('history_data').once().then((DatabaseEvent event) {
      try {
        final data = event.snapshot.value;
        final List<LogEntry> logs = [];

        print('📊 Data received from Firebase: ${data != null ? "Data exists" : "null"}');

        if (data != null && data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              print('🔍 Processing log entry: $key');
              
              try {
                // PERBAIKAN: Gunakan key sebagai timestamp utama
                final int timestamp = _parseKeyToTimestamp(key.toString());
                
                logs.add(LogEntry(
                  id: key.toString(),
                  timestamp: timestamp,
                  action: _generateActionText(value),
                  type: 'sensor',
                  temperature: _toDouble(value['suhu']),
                  humidity: _toDouble(value['kelembaban_udara']),
                  soilMoisture: _toDouble(value['kelembaban_tanah']),
                  value: _toDouble(value['kecerahan']),
                  unit: '%',
                  brightness: _toDouble(value['kecerahan']),
                  soilCategory: value['kategori_tanah']?.toString(),
                  lightCategory: value['kategori_cahaya']?.toString(),
                  operationMode: value['mode_operasi']?.toString(),
                  pumpStatus: value['status_pompa']?.toString(),
                  temperatureStatus: value['status_suhu']?.toString(),
                  humidityStatus: value['status_kelembaban']?.toString(),
                  plantStage: value['tahapan_tanaman']?.toString(),
                  plantAge: _toDouble(value['umur_tanaman']),
                  timeOfDay: value['waktu']?.toString(),
                  datetime: value['datetime']?.toString(),
                ));
              } catch (e) {
                print('❌ Error processing entry $key: $e');
              }
            }
          });
        }

        // PERBAIKAN: Sort by timestamp descending (terbaru di atas) berdasarkan key
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        print('✅ Successfully loaded ${logs.length} logs');

        setState(() {
          _logs = logs;
          _isLoading = false;
          _hasError = false;
        });
      } catch (e) {
        print('❌ Error loading logs: $e');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }).catchError((error) {
      print('❌ Error fetching logs: $error');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  // PERBAIKAN: Fungsi untuk parsing key menjadi timestamp
  int _parseKeyToTimestamp(String key) {
    try {
      // Key adalah millis() dari Arduino, langsung konversi ke int
      final millis = int.tryParse(key);
      if (millis != null) {
        return millis;
      }
    } catch (e) {
      print('❌ Error parsing key $key: $e');
    }
    
    // Fallback: gunakan waktu sekarang
    return DateTime.now().millisecondsSinceEpoch;
  }

  int _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    
    if (timestamp is int) {
      if (timestamp < 10000000000) {
        return timestamp * 1000;
      }
      return timestamp;
    }
    
    if (timestamp is String) {
      final parsed = int.tryParse(timestamp);
      if (parsed != null) {
        if (parsed < 10000000000) {
          return parsed * 1000;
        }
        return parsed;
      }
      
      try {
        final dateTime = DateTime.tryParse(timestamp);
        if (dateTime != null) {
          return dateTime.millisecondsSinceEpoch;
        }
      } catch (e) {
        print('❌ Error parsing datetime string: $e');
      }
    }
    
    return DateTime.now().millisecondsSinceEpoch;
  }

  String _generateActionText(Map<dynamic, dynamic> data) {
    final plantStage = data['tahapan_tanaman']?.toString() ?? 'Tanaman';
    final soilCategory = data['kategori_tanah']?.toString() ?? '';
    final mode = data['mode_operasi']?.toString() ?? 'AUTO';
    
    return '$plantStage - $soilCategory ($mode)';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📊 Riwayat Monitoring 2025',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Summary Cards
              _buildSummaryCards(),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                        ? _buildErrorState()
                        : _logs.isEmpty
                            ? _buildEmptyState()
                            : _buildLogList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data History SmartFarm Tomat 2025',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_logs.length} data monitoring ditemukan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tahapan: ${_getCurrentPlantStage()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.green, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final drySoilCount = _logs.where((log) => log.soilCategory == 'SANGAT KERING' || log.soilCategory == 'KERING').length;
    final pumpOnCount = _logs.where((log) => log.pumpStatus == 'ON').length;
    final autoModeCount = _logs.where((log) => log.operationMode == 'AUTO').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Ringkasan Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Total Data', _logs.length.toString(), Icons.list, Colors.blue),
              _buildSummaryCard('Tanah Kering', drySoilCount.toString(), Icons.grass, Colors.orange),
              _buildSummaryCard('Pompa ON', pumpOnCount.toString(), Icons.water_drop, Colors.blue),
              _buildSummaryCard('Auto Mode', autoModeCount.toString(), Icons.smart_toy, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLogList() {
    return Column(
      children: [
        // List Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Riwayat Monitoring',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_logs.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: ListView.separated(
            itemCount: _logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = _logs[index];
              return _buildLogItem(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeFormat = DateFormat('HH:mm:ss'); // PERBAIKAN: tambah detik
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isToday = DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon dengan status
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(log),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(log),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan tahapan tanaman
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.plantStage ?? 'Tanaman',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.operationMode == 'AUTO' ? Colors.blue.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mode: ${log.operationMode ?? 'AUTO'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: log.operationMode == 'AUTO' ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Data sensor utama
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: _buildSensorData(log),
                ),
                const SizedBox(height: 8),

                // Status tambahan
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _buildStatusChips(log),
                ),
                
                // PERBAIKAN: Tampilkan datetime asli dari Firebase jika ada
                if (log.datetime != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Waktu: ${log.datetime}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeFormat.format(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade800 : Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isToday ? 'Hari Ini' : dateFormat.format(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSensorData(LogEntry log) {
    return [
      if (log.temperature != null)
        _buildSensorItem('🌡', '${log.temperature!.toStringAsFixed(1)}°C', Colors.red),
      if (log.humidity != null)
        _buildSensorItem('💧', '${log.humidity!.toStringAsFixed(1)}%', Colors.blue),
      if (log.soilMoisture != null)
        _buildSensorItem('🌱', '${log.soilMoisture!.toStringAsFixed(1)}%', Colors.green),
      if (log.brightness != null)
        _buildSensorItem('💡', '${log.brightness!.toStringAsFixed(1)}%', Colors.orange),
    ];
  }

  Widget _buildSensorItem(String icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStatusChips(LogEntry log) {
    final chips = <Widget>[];
    
    if (log.soilCategory != null) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getSoilColor(log.soilCategory!).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Tanah: ${log.soilCategory}',
            style: TextStyle(
              fontSize: 10,
              color: _getSoilColor(log.soilCategory!),
            ),
          ),
        ),
      );
    }
    
    if (log.pumpStatus != null) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: log.pumpStatus == 'ON' ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Pompa: ${log.pumpStatus}',
            style: TextStyle(
              fontSize: 10,
              color: log.pumpStatus == 'ON' ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    if (log.timeOfDay != null) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: log.timeOfDay == 'Siang' ? Colors.orange.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            log.timeOfDay!,
            style: TextStyle(
              fontSize: 10,
              color: log.timeOfDay == 'Siang' ? Colors.orange.shade700 : Colors.blue.shade700,
            ),
          ),
        ),
      );
    }
    
    return chips;
  }

  Color _getStatusColor(LogEntry log) {
    if (log.pumpStatus == 'ON') return Colors.green;
    if (log.soilCategory == 'SANGAT KERING') return Colors.red;
    if (log.soilCategory == 'KERING') return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(LogEntry log) {
    if (log.pumpStatus == 'ON') return Icons.water_drop;
    if (log.soilCategory == 'SANGAT KERING') return Icons.warning;
    return Icons.sensors;
  }

  Color _getSoilColor(String soilCategory) {
    switch (soilCategory) {
      case 'SANGAT KERING':
        return Colors.red;
      case 'KERING':
        return Colors.orange;
      case 'LEMBAB':
        return Colors.green;
      case 'BASAH':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getCurrentPlantStage() {
    if (_logs.isEmpty) return 'Tidak ada data';
    final latestLog = _logs.first;
    return latestLog.plantStage ?? 'Unknown';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat data monitoring 2025...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.data_array,
              size: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data monitoring',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class LogEntry {
  final String id;
  final int timestamp;
  final String action;
  final String type;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? value;
  final String? unit;
  
  final double? brightness;
  final String? soilCategory;
  final String? lightCategory;
  final String? operationMode;
  final String? pumpStatus;
  final String? temperatureStatus;
  final String? humidityStatus;
  final String? plantStage;
  final double? plantAge;
  final String? timeOfDay;
  final String? datetime;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.type,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.value,
    this.unit,
    this.brightness,
    this.soilCategory,
    this.lightCategory,
    this.operationMode,
    this.pumpStatus,
    this.temperatureStatus,
    this.humidityStatus,
    this.plantStage,
    this.plantAge,
    this.timeOfDay,
    this.datetime,
  });
}