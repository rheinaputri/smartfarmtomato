import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/home_screen.dart';
import '../../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _notificationsEnabled = true;
  bool _autoRefreshEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _autoRefreshEnabled = prefs.getBool('autoRefresh') ?? true;
    });
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    _showSnackBar('Notifikasi ${value ? 'diaktifkan' : 'dinonaktifkan'}');
  }

  void _toggleAutoRefresh(bool value) async {
    setState(() {
      _autoRefreshEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoRefresh', value);
    _showSnackBar('Auto refresh ${value ? 'diaktifkan' : 'dinonaktifkan'}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        title: Row(
          children: [
            Icon(Icons.agriculture, color: isDarkMode ? Colors.green.shade300 : Colors.green),
            const SizedBox(width: 8),
            Text(
              'Tentang TomaFarm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isDarkMode 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade900, Colors.green.shade800],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                      ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '🍅 TomaFarm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smart Tomato Farming System',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi TomaFarm adalah sistem monitoring dan kontrol otomatis untuk budidaya tanaman tomat. '
                'Dilengkapi dengan berbagai fitur canggih untuk memastikan tanaman tomat tumbuh optimal.',
                style: TextStyle(
                  height: 1.5,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🎯 Fitur Utama:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('📊 Monitoring real-time sensor', isDarkMode),
              _buildFeatureItem('💧 Kontrol otomatis pompa air', isDarkMode),
              _buildFeatureItem('💡 Kontrol lampu tumbuh', isDarkMode),
              _buildFeatureItem('📈 Riwayat data dan grafik', isDarkMode),
              _buildFeatureItem('🔔 Notifikasi cerdas', isDarkMode),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Informasi Teknis:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi: 1.0.0\nBuild: 2024.12.01\nDikembangkan untuk Project Based Learning',
                      style: TextStyle(
                        fontSize: 11, 
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: isDarkMode ? Colors.green.shade300 : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Konfirmasi Logout',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin logout dari akun Anda?',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog terlebih dahulu
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // PERBAIKAN: Pisahkan fungsi logout ke method terpisah
  Future<void> _performLogout() async {
    try {
      await _auth.signOut();
      
      // PERBAIKAN: Gunakan Navigator dengan context yang benar
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // PERBAIKAN: Tambahkan error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAccountInfo() {
    final user = _auth.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        title: Row(
          children: [
            Icon(Icons.person, color: isDarkMode ? Colors.blue.shade300 : Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Informasi Akun',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountInfoItem('Nama', user?.displayName ?? 'Tidak diatur', isDarkMode),
            _buildAccountInfoItem('Email', user?.email ?? 'Tidak tersedia', isDarkMode),
            _buildAccountInfoItem(
              'Status Email',
              user?.emailVerified == true ? 'Terverifikasi' : 'Belum diverifikasi',
              isDarkMode,
            ),
            _buildAccountInfoItem(
              'Bergabung',
              user?.metadata.creationTime != null 
                  ? '${DateTime.now().difference(user!.metadata.creationTime!).inDays} hari yang lalu'
                  : 'Tidak tersedia',
              isDarkMode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoItem(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚙️ Pengaturan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade900, Colors.black87],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE8F5E8), Colors.white],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? user?.email?.split('@').first ?? 'Pengguna TomaFarm',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'email@example.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user?.emailVerified == true 
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user?.emailVerified == true ? '✓ Email Terverifikasi' : '! Verifikasi Email',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showAccountInfo,
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        tooltip: 'Info Akun',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings List
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings, 
                              color: isDarkMode ? Colors.green.shade300 : Colors.green, 
                              size: 20
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pengaturan Aplikasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.green.shade300 : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_active,
                        title: 'Notifikasi Sistem',
                        subtitle: 'Terima notifikasi kondisi tanaman',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeColor: Colors.green,
                          activeTrackColor: Colors.green.shade200,
                        ),
                        isDarkMode: isDarkMode,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildSettingItem(
                        icon: Icons.dark_mode,
                        title: 'Mode Gelap',
                        subtitle: 'Tampilan tema gelap',
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                            _showSnackBar('Mode gelap ${value ? 'diaktifkan' : 'dinonaktifkan'}');
                          },
                          activeColor: Colors.blue,
                          activeTrackColor: Colors.blue.shade200,
                        ),
                        isDarkMode: isDarkMode,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildSettingItem(
                        icon: Icons.refresh,
                        title: 'Auto Refresh',
                        subtitle: 'Refresh data otomatis',
                        trailing: Switch(
                          value: _autoRefreshEnabled,
                          onChanged: _toggleAutoRefresh,
                          activeColor: Colors.orange,
                          activeTrackColor: Colors.orange.shade200,
                        ),
                        isDarkMode: isDarkMode,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildSettingItem(
                        icon: Icons.language,
                        title: 'Bahasa',
                        subtitle: 'Bahasa Indonesia',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.green.shade800 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.green.shade300 : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          _showSnackBar('Bahasa Indonesia aktif');
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildSettingItem(
                        icon: Icons.info_outline,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Versi 1.0.0',
                        trailing: Icon(
                          Icons.chevron_right, 
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey
                        ),
                        onTap: _showAboutDialog,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // PERBAIKAN: Logout Button dengan gesture detector tambahan
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showLogoutConfirmation,
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        color: Colors.red.shade600,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: Colors.white),
                              const SizedBox(width: 12),
                              const Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? Colors.green.withOpacity(0.2)
              : Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: isDarkMode ? Colors.green.shade300 : Colors.green, 
          size: 22
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }
}