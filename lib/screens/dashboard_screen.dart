import 'package:certiverify/models/certificate.dart';
import 'package:certiverify/screens/certificate_details_screen.dart';
import 'package:certiverify/screens/check_credential_screen.dart';
import 'package:certiverify/screens/graduate_certificates_screen.dart';
import 'package:certiverify/screens/institution_screen.dart';
import 'package:certiverify/screens/issue__certificate_screen.dart';
import 'package:certiverify/screens/my_certificate_screen.dart';
import 'package:certiverify/screens/qr_scanner_screen.dart';
import 'package:certiverify/screens/revoke_certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/certificate_provider.dart';
import '../utils/theme.dart';
import '../widgets/bottom_nav_bar.dart';

import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const MyCertificatesScreen(),
    const QRScannerScreen(),
    const InstitutionsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // final user = authProvider.currentUser;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// In dashboard_screen.dart, update the _HomeContent widget

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final certProvider = Provider.of<CertificateProvider>(context);
    final user = authProvider.currentUser;
    final isAdmin = user?.isInstitutionAdmin ?? false;
    final isStudent = user?.isStudent ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 16,
            // backgroundColor: AppTheme.primaryContainer.withOpacity(0.2),
            child: Text(
              user?.name[0].toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => certProvider.fetchUserCertificates(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isStudent
                      ? AppTheme.secondaryContainer
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStudent ? Icons.school : null,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStudent
                                ? 'Welcome, ${user?.name ?? 'Student'}!'
                                : 'Welcome back, ${user?.name.split(' ')[0] ?? 'User'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isStudent && user?.studentId != null)
                            Text(
                              'Student ID: ${user?.studentId}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          if (!isStudent)
                            Text(
                              'Your credentials have been verified ${certProvider.totalVerificationCount} times this month.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            )
                          else if (isAdmin)
                            Text(
                              "You have ${certProvider.userCertificates.length} active certificates.",
                            )
                          else
                            Text(" "),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats cards (different for student vs admin)
              if (isStudent)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'My Certificates',
                        value: '${certProvider.userCertificates.length}',
                        icon: Icons.school,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Verifications',
                        value: '${certProvider.totalVerificationCount}',
                        icon: Icons.verified,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'TOTAL ISSUED',
                            value: '${certProvider.userCertificates.length}',
                            icon: Icons.school,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'VERIFIED',
                            value: '${certProvider.totalVerificationCount}',
                            icon: Icons.verified,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'GRADUATES',
                            value: '30',
                            icon: Icons.people_alt_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'BLOCKCHAIN',
                            value: 'Healthy',
                            icon: Icons.dashboard_outlined,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Action buttons (different for student vs admin) on dashboard
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              if (isStudent)
                // Student Actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Verify QR',
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.primaryContainer.withOpacity(
                          0.1,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.history_edu,
                        label: 'MY CERTS',
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.primaryContainer.withOpacity(
                          0.1,
                        ),
                        onTap: () {
                          // Navigate to certificates
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GraduateCredentialsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else if (isAdmin)
                // Admin Actions
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Scan Qr Code',
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.primaryContainer
                                .withOpacity(0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QRScannerScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.history_edu,
                            label: 'My Certs',
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.primaryContainer
                                .withOpacity(0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CredentialDetailsScreen(
                                        credentialId: '<CREDENTIAL_ID>',
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_moderator,
                            label: 'Issue Credential',
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.surface,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const IssueCertificateScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: _ActionButton(
                            icon: Icons.verified,
                            label: 'Check Credential',
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.primaryContainer
                                .withOpacity(0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CheckCredentialScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.cancel,
                            label: 'REVOKE CERTIFICATE',
                            backgroundColor: AppTheme.error.withOpacity(0.01),
                            color: AppTheme.error,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RevokeCertificateScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.account_balance,
                            label: 'INSTITUTIONS',
                            color: AppTheme.primary,
                            backgroundColor: AppTheme.primaryContainer
                                .withOpacity(0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InstitutionsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                // Verifier Actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan QR',
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.primaryContainer.withOpacity(
                          0.1,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.verified,
                        label: 'Verify Credential',
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.primaryContainer.withOpacity(
                          0.1,
                        ),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Recent activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              if (certProvider.recentVerifications.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      isStudent
                          ? 'No recent verifications of your certificates'
                          : 'No recent activity',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...certProvider.recentVerifications
                    .take(3)
                    .map((cert) => _ActivityItem(certificate: cert)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: color, fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Certificate certificate;

  const _ActivityItem({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.history_edu, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.degree,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Issued to: ${certificate.studentName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getTimeAgo(certificate.issuedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SYNCED',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
