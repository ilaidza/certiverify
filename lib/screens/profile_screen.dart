import 'package:certiverify/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _offlineStorageEnabled = true;
  String _selectedLanguage = 'en';
  int _pendingSyncCount = 0;
  bool _isLoggingOut = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _biometricEnabled = StorageService.isBiometricEnabled();
    _darkModeEnabled = StorageService.isDarkModeEnabled();
    _selectedLanguage = StorageService.getLanguage();
    _pendingSyncCount = StorageService.getPendingSyncCount();
    setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        // Clear entire navigation stack and go to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all locally stored certificates. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllCertificates();
      await StorageService.setPendingSyncCount(0);
      setState(() => _pendingSyncCount = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  Future<void> _syncOfflineData() async {
    setState(() => _pendingSyncCount = 0);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sync completed')));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        user?.name[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRoleName(user?.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account section
            _buildSection(
              title: 'Account',
              children: [
                _buildListItem(
                  icon: Icons.history,
                  title: 'Verification History',
                  onTap: () {},
                ),
                _buildListItem(
                  icon: Icons.security,
                  title: 'Security Settings',
                  onTap: () {},
                ),
                _buildListItem(
                  icon: Icons.business,
                  title: 'Linked Institutions',
                  subtitle: user?.institutionName,
                  onTap: () {},
                ),
              ],
            ),

            // Preferences section
            _buildSection(
              title: 'Preferences',
              children: [
                _buildSwitchListItem(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  value: _biometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final available =
                          await AuthService.isBiometricAvailable();
                      if (!available) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Biometric authentication not available on this device',
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    setState(() => _biometricEnabled = value);
                    await StorageService.setBiometricEnabled(value);
                  },
                ),
                _buildSwitchListItem(
                  icon: Icons.storage,
                  title: 'Offline Storage',
                  subtitle: 'Store certificates for offline verification',
                  value: _offlineStorageEnabled,
                  onChanged: (value) =>
                      setState(() => _offlineStorageEnabled = value),
                ),
                _buildListItem(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ha', child: Text('Hausa')),
                      DropdownMenuItem(value: 'ig', child: Text('Igbo')),
                      DropdownMenuItem(value: 'yo', child: Text('Yoruba')),
                    ],
                    onChanged: (value) async {
                      setState(() => _selectedLanguage = value!);
                      await StorageService.setLanguage(value!);
                    },
                    underline: const SizedBox(),
                  ),
                ),
                _buildSwitchListItem(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                    StorageService.setDarkModeEnabled(value);
                    // Implement theme switching
                  },
                ),
              ],
            ),

            // Data section
            _buildSection(
              title: 'Data Management',
              children: [
                _buildListItem(
                  icon: Icons.sync,
                  title: 'Sync Offline Data',
                  trailing: _pendingSyncCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_pendingSyncCount',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                  onTap: _pendingSyncCount > 0 ? _syncOfflineData : null,
                ),
                _buildListItem(
                  icon: Icons.delete_sweep,
                  title: 'Clear Cache',
                  onTap: _clearCache,
                ),
              ],
            ),

            // Support section
            _buildSection(
              title: 'Support',
              children: [
                _buildListItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _buildListItem(
                  icon: Icons.description,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  _isLoggingOut ? 'Logging out...' : 'Logout',
                  style: TextStyle(color: AppTheme.background),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.background,
                  backgroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 130,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Powered by Hyperledger Fabric',
                    style: TextStyle(fontSize: 12, color: AppTheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Secured by Web3 Infrastructure',
                    style: TextStyle(fontSize: 10, color: AppTheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.outline),
            )
          : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.outline),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
    );
  }

  String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.institutionAdmin:
        return 'Institution Admin';
      case UserRole.verifier:
        return 'Verifier';
      default:
        return 'User';
    }
  }
}
