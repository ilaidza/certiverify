import 'package:certiverify/models/certificate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'certificate_details_screen.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _allCertificates = [];
  List<Map<String, dynamic>> _filteredCertificates = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCertificates = 0;
  final int _limit = 10;

  late TabController _tabController;
  String _currentFilter = 'all'; // all, active, revoked

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchCertificates();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'all';
            break;
          case 1:
            _currentFilter = 'active';
            break;
          case 2:
            _currentFilter = 'revoked';
            break;
        }
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case 'active':
          _filteredCertificates = _allCertificates
              .where((cert) => cert['status'] == 'active')
              .toList();
          break;
        case 'revoked':
          _filteredCertificates = _allCertificates
              .where((cert) => cert['status'] == 'revoked')
              .toList();
          break;
        default:
          _filteredCertificates = List.from(_allCertificates);
      }
    });
  }

  Future<void> _fetchCertificates({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.isInstitutionAdmin ?? false;
    final isStudent = authProvider.currentUser?.isStudent ?? false;

    late Map<String, dynamic> result;

    if (isAdmin) {
      result = await _apiService.getInstitutionCredentials(
        page: _currentPage,
        limit: _limit,
      );
    } else if (isStudent) {
      final graduateResult = await _apiService.getGraduateCredentials();
      if (graduateResult['success']) {
        result = {
          'success': true,
          'credentials': graduateResult['credentials'] ?? [],
          'pagination': {
            'page': 1,
            'limit': 10,
            'total': graduateResult['total'] ?? 0,
            'total_pages': 1,
          },
        };
      } else {
        result = {'success': false, 'error': graduateResult['error']};
      }
    } else {
      final userCredentials = await _apiService.getUserCredentials();
      if (userCredentials is List) {
        result = {
          'success': true,
          'credentials': userCredentials,
          'pagination': {
            'page': 1,
            'limit': 10,
            'total': userCredentials.length,
            'total_pages': 1,
          },
        };
      } else {
        result = {'success': false, 'error': 'Failed to load credentials'};
      }
    }

    if (loadMore) {
      setState(() => _isLoadingMore = false);
    } else {
      setState(() => _isLoading = false);
    }

    if (result['success']) {
      // SAFELY handle credentials - ensure it's a list
      List<Map<String, dynamic>> credentialsList = [];
      final credentialsData = result['credentials'];

      if (credentialsData != null) {
        if (credentialsData is List) {
          credentialsList = credentialsData
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (credentialsData is Map) {
          credentialsList = [Map<String, dynamic>.from(credentialsData)];
        }
      }

      final pagination = result['pagination'];

      setState(() {
        if (loadMore) {
          _allCertificates.addAll(credentialsList);
        } else {
          _allCertificates = credentialsList;
        }

        _totalCertificates = pagination?['total'] ?? credentialsList.length;
        _totalPages = pagination?['total_pages'] ?? 1;
        _applyFilter();
      });
    } else {
      if (!loadMore) {
        setState(
          () => _error = result['error'] ?? 'Failed to load certificates',
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await _fetchCertificates(loadMore: true);
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    await _fetchCertificates();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isInstitutionAdmin ?? false;
    final isStudent = authProvider.currentUser?.isStudent ?? false;
    final studentId = authProvider.currentUser?.studentId ?? '';

    final activeCount = _allCertificates
        .where((c) => c['status'] == 'active')
        .length;
    final revokedCount = _allCertificates
        .where((c) => c['status'] == 'revoked')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Issued Certificates' : 'My Certificates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'ALL (${_allCertificates.length})'),
            Tab(text: 'ACTIVE ($activeCount)'),
            Tab(text: 'REVOKED ($revokedCount)'),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchCertificates,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : _filteredCertificates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentFilter == 'active'
                          ? Icons.check_circle_outline
                          : _currentFilter == 'revoked'
                          ? Icons.cancel_outlined
                          : Icons.history_edu,
                      size: 80,
                      color: AppTheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentFilter == 'active'
                          ? 'No active certificates'
                          : _currentFilter == 'revoked'
                          ? 'No revoked certificates'
                          : isAdmin
                          ? 'No certificates issued yet'
                          : 'No certificates found',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                    if (isStudent && studentId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Student ID: $studentId',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.outline,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (isAdmin && _allCertificates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap + to issue a new certificate',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount:
                    _filteredCertificates.length +
                    (_currentPage < _totalPages ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _filteredCertificates.length) {
                    return _buildLoaderMore();
                  }
                  final cert = _filteredCertificates[index];
                  return _CertificateCard(
                    certificate: cert,
                    isAdmin: isAdmin,
                    // In my_certificates_screen.dart, update the onTap:
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CredentialDetailsScreen(
                            credentialId: cert['credential_id'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLoaderMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Call this when scrolling to load more
  void _onScroll(ScrollController controller) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
}

class _CertificateCard extends StatelessWidget {
  final Map<String, dynamic> certificate;
  final bool isAdmin;
  final VoidCallback onTap;

  const _CertificateCard({
    required this.certificate,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = certificate['status'] == 'active';
    final studentName = certificate['student_name'] ?? '';
    final studentId = certificate['student_id'] ?? '';
    final degree = certificate['degree'] ?? 'Unknown Degree';
    final institution =
        certificate['institution_name'] ??
        certificate['institution'] ??
        'Unknown Institution';
    final graduationDate = certificate['graduation_date'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.secondary : AppTheme.error,
            width: 1.5,
          ),
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
            // Icon based on status
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.secondary : AppTheme.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? Icons.school : Icons.cancel,
                size: 28,
                color: isActive ? AppTheme.secondary : AppTheme.error,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    degree,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    institution,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppTheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(graduationDate),
                        style: TextStyle(fontSize: 12, color: AppTheme.outline),
                      ),
                    ],
                  ),
                  if (isAdmin && studentName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Student: $studentName ($studentId)',
                        style: TextStyle(fontSize: 11, color: AppTheme.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.secondary : AppTheme.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                certificate['status']?.toUpperCase() ?? 'UNKNOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.secondary : AppTheme.error,
                ),
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }
}
