import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/certificate_provider.dart';
import '../models/certificate.dart';
import '../utils/theme.dart';
import 'certificate_details_screen.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CertificateProvider>(
        context,
        listen: false,
      ).fetchUserCertificates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Certificate> _getFilteredCertificates(List<Certificate> certificates) {
    var filtered = certificates;

    // Filter by tab
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Active
        filtered = filtered.where((c) => c.isActive).toList();
        break;
      case 2: // Revoked
        filtered = filtered.where((c) => c.isRevoked).toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.studentName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                c.degree.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.matricNumber.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final certProvider = Provider.of<CertificateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'ACTIVE'),
            Tab(text: 'REVOKED'),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search certificates...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineVariant),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Certificate list
          Expanded(
            child: certProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : certProvider.userCertificates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 80,
                          color: AppTheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No certificates found',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => certProvider.fetchUserCertificates(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _getFilteredCertificates(
                        certProvider.userCertificates,
                      ).length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cert = _getFilteredCertificates(
                          certProvider.userCertificates,
                        )[index];
                        return _CertificateListItem(certificate: cert);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CertificateListItem extends StatelessWidget {
  final Certificate certificate;

  const _CertificateListItem({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CertificateDetailsScreen(certificate: certificate),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // QR code thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),

            // Certificate info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificate.degree,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    certificate.institution,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issued: ${certificate.issueDate}',
                    style: TextStyle(fontSize: 12, color: AppTheme.outline),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: certificate.isActive
                    ? AppTheme.secondaryContainer.withOpacity(0.3)
                    : AppTheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                certificate.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: certificate.isActive
                      ? AppTheme.secondary
                      : AppTheme.error,
                ),
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}
