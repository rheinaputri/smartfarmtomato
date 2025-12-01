import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart'; 
import '../../../providers/theme_provider.dart'; 

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  bool _pumpStatus = false;
  bool _lightStatus = false;
  bool _autoMode = true;

  @override
  void initState() {
    super.initState();
    _loadControlStatus();
  }

  void _loadControlStatus() {
    _databaseRef.child('control').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _pumpStatus = data['pump'] == true;
          _lightStatus = data['light'] == true;
          _autoMode = data['autoMode'] == true;
        });
      }
    });
  }

  void _togglePump() {
    setState(() {
      _pumpStatus = !_pumpStatus;
    });
    _databaseRef.child('control/pump').set(_pumpStatus);
    _logAction('Pompa Air ${_pumpStatus ? 'DIHIDUPKAN' : 'DIMATIKAN'}');
  }

  void _toggleLight() {
    setState(() {
      _lightStatus = !_lightStatus;
    });
    _databaseRef.child('control/light').set(_lightStatus);
    _logAction('Lampu Tumbuh ${_lightStatus ? 'DIHIDUPKAN' : 'DIMATIKAN'}');
  }

  void _toggleAutoMode() {
    setState(() {
      _autoMode = !_autoMode;
    });
    _databaseRef.child('control/autoMode').set(_autoMode);
    _logAction('Mode ${_autoMode ? 'OTOMATIS' : 'MANUAL'} diaktifkan');
  }

  void _logAction(String action) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _databaseRef.child('logs').push().set({
      'timestamp': timestamp,
      'action': action,
      'type': 'control',
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Kontrol Aktuator'),
        backgroundColor: themeProvider.isDarkMode ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Kontrol manual pompa air dan lampu tumbuh',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              _buildControlMode(context),
              const SizedBox(height: 24),
              _buildPumpControl(context),
              const SizedBox(height: 24),
              _buildLightControl(context),
              const SizedBox(height: 24),
              _buildSystemStatus(context),
              const SizedBox(height: 24),
              _buildControlInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlMode(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _autoMode 
          ? (themeProvider.isDarkMode ? Colors.green.shade900.withOpacity(0.3) : Colors.green[50]!)
          : (themeProvider.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue[50]!),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _autoMode 
            ? Colors.green.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
            : Colors.blue.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _autoMode 
                ? Colors.green.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2)
                : Colors.blue.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _autoMode ? Icons.auto_mode : Icons.engineering,
              color: _autoMode ? Colors.green : Colors.blue,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _autoMode ? '🤖 Mode Otomatis' : '👨‍💻 Mode Manual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _autoMode ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _autoMode 
                    ? 'Sistem mengontrol secara otomatis berdasarkan kondisi sensor'
                    : 'Kontrol manual diaktifkan - Anda dapat mengontrol pompa dan lampu',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoMode,
            onChanged: (value) => _toggleAutoMode(),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildPumpControl(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                '💧 Kontrol Pompa Air',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _pumpStatus 
                          ? Colors.green.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1)
                          : Colors.red.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _pumpStatus ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        _pumpStatus ? '🟢 MENYALA' : '🔴 MATI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _pumpStatus ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pumpStatus 
                        ? 'Pompa aktif mengalirkan air ke tanaman'
                        : 'Pompa dalam kondisi non-aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _autoMode 
                    ? Colors.grey.withOpacity(0.5)
                    : (_pumpStatus ? Colors.green : Colors.red),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_autoMode 
                        ? Colors.grey 
                        : (_pumpStatus ? Colors.green : Colors.red)
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _autoMode ? null : _togglePump,
                  icon: Icon(
                    _pumpStatus ? Icons.power_settings_new : Icons.power_off,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (_autoMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info, 
                    color: themeProvider.isDarkMode ? Colors.orange.shade300 : Colors.orange[700], 
                    size: 16
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode otomatis aktif - Kontrol manual dinonaktifkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.isDarkMode ? Colors.orange.shade300 : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLightControl(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                '💡 Kontrol Lampu Tumbuh',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.amber.shade300 : Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lightStatus 
                          ? Colors.green.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1)
                          : Colors.red.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _lightStatus ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        _lightStatus ? '🟢 MENYALA' : '🔴 MATI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _lightStatus ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lightStatus 
                        ? 'Lampu aktif menyinari tanaman'
                        : 'Lampu dalam kondisi non-aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _autoMode 
                    ? Colors.grey.withOpacity(0.5)
                    : (_lightStatus ? Colors.green : Colors.red),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_autoMode 
                        ? Colors.grey 
                        : (_lightStatus ? Colors.green : Colors.red)
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _autoMode ? null : _toggleLight,
                  icon: Icon(
                    _lightStatus ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (_autoMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info, 
                    color: themeProvider.isDarkMode ? Colors.orange.shade300 : Colors.orange[700], 
                    size: 16
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode otomatis aktif - Kontrol manual dinonaktifkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.isDarkMode ? Colors.orange.shade300 : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemStatus(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Status Sistem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.purple.shade300 : Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusIndicator(
                'Koneksi IoT',
                Icons.wifi,
                Colors.green,
                'Aktif',
                context,
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                'Database',
                Icons.storage,
                Colors.green,
                'Online',
                context,
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                'Sensor',
                Icons.sensors,
                Colors.green,
                'Aktif',
                context,
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                'Aktuator',
                Icons.engineering,
                _autoMode ? Colors.green : Colors.blue,
                _autoMode ? 'Auto' : 'Manual',
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, IconData icon, Color color, String status, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(themeProvider.isDarkMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlInfo(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(themeProvider.isDarkMode ? 0.2 : 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help, 
                color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey
              ),
              const SizedBox(width: 8),
              Text(
                'ℹ️ Informasi Kontrol',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Mode Otomatis: Sistem akan mengontrol pompa dan lampu secara otomatis berdasarkan data sensor',
            context,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            'Mode Manual: Anda dapat mengontrol pompa dan lampu secara manual melalui tombol kontrol',
            context,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            'Status real-time: Semua perubahan status akan langsung terlihat di dashboard',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}