// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../services/api_service.dart';
// import '../utils/theme.dart';

// class GraduateCertificatesScreen extends StatefulWidget {
//   const GraduateCertificatesScreen({super.key});

//   @override
//   State<GraduateCertificatesScreen> createState() =>
//       _GraduateCertificatesScreenState();
// }

// class _GraduateCertificatesScreenState
//     extends State<GraduateCertificatesScreen> {
//   final ApiService _apiService = ApiService();

//   List<Map<String, dynamic>> _certificates = [];
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCertificates();
//   }

//   Future<void> _fetchCertificates() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     final result = await _apiService.getGraduateCredentials();

//     setState(() {
//       _isLoading = false;
//       if (true) {
//         _certificates = List<Map<String, dynamic>>.from(result);
//       }
//     });
//   }

//   Future<void> _refresh() async {
//     await _fetchCertificates();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final studentId = authProvider.currentUser?.studentId ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Certificates'),
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refresh,
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _error != null
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 64, color: AppTheme.error),
//                     const SizedBox(height: 16),
//                     Text(
//                       _error!,
//                       style: TextStyle(color: AppTheme.onSurfaceVariant),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _fetchCertificates,
//                       child: const Text('Try Again'),
//                     ),
//                   ],
//                 ),
//               )
//             : _certificates.isEmpty
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.history_edu, size: 80, color: AppTheme.outline),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No certificates found',
//                       style: TextStyle(color: AppTheme.onSurfaceVariant),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Student ID: $studentId',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppTheme.outline,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             : ListView.separated(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: _certificates.length,
//                 separatorBuilder: (context, index) =>
//                     const SizedBox(height: 12),
//                 itemBuilder: (context, index) {
//                   final cert = _certificates[index];
//                   return _CertificateCard(
//                     certificate: cert,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => GraduateCertificateDetailScreen(
//                             credentialId: cert['credential_id'],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

// class _CertificateCard extends StatelessWidget {
//   final Map<String, dynamic> certificate;
//   final VoidCallback onTap;

//   const _CertificateCard({required this.certificate, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final isActive = certificate['status'] == 'active';

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isActive ? AppTheme.secondary : AppTheme.error,
//             width: 1,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: AppTheme.primary.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Icon
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: (isActive ? AppTheme.secondary : AppTheme.error)
//                     .withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 isActive ? Icons.school : Icons.cancel,
//                 size: 28,
//                 color: isActive ? AppTheme.secondary : AppTheme.error,
//               ),
//             ),
//             const SizedBox(width: 16),

//             // Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     certificate['degree'] ?? 'Unknown Degree',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     certificate['institution'] ?? 'Unknown Institution',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: AppTheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         size: 12,
//                         color: AppTheme.outline,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         _formatDate(certificate['graduation_date'] ?? ''),
//                         style: TextStyle(fontSize: 12, color: AppTheme.outline),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Status Badge
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(
//                 color: (isActive ? AppTheme.secondary : AppTheme.error)
//                     .withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 certificate['status']?.toUpperCase() ?? 'UNKNOWN',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                   color: isActive ? AppTheme.secondary : AppTheme.error,
//                 ),
//               ),
//             ),

//             const SizedBox(width: 8),
//             const Icon(Icons.chevron_right, size: 20, color: AppTheme.outline),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(String dateString) {
//     if (dateString.isEmpty) return 'Unknown';
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return dateString.split('T')[0];
//     }
//   }
// }

// class GraduateCertificateDetailScreen extends StatefulWidget {
//   final String credentialId;

//   const GraduateCertificateDetailScreen({
//     super.key,
//     required this.credentialId,
//   });

//   @override
//   State<GraduateCertificateDetailScreen> createState() =>
//       _GraduateCertificateDetailScreenState();
// }

// class _GraduateCertificateDetailScreenState
//     extends State<GraduateCertificateDetailScreen> {
//   final ApiService _apiService = ApiService();

//   Map<String, dynamic>? _certificate;
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCertificate();
//   }

//   Future<void> _fetchCertificate() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     final result = await _apiService.getGraduateCredential(widget.credentialId);

//     setState(() {
//       _isLoading = false;
//       if (result['success']) {
//         _certificate = result;
//       } else {
//         _error = result['error'];
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isActive = _certificate?['status'] == 'active';

//     return Scaffold(
//       appBar: AppBar(title: const Text('Certificate Details')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 64, color: AppTheme.error),
//                   const SizedBox(height: 16),
//                   Text(_error!),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _fetchCertificate,
//                     child: const Text('Try Again'),
//                   ),
//                 ],
//               ),
//             )
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   // Status Card
//                   Container(
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: (isActive ? AppTheme.secondary : AppTheme.error)
//                           .withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Column(
//                       children: [
//                         Icon(
//                           isActive ? Icons.verified : Icons.cancel,
//                           size: 80,
//                           color: isActive ? AppTheme.secondary : AppTheme.error,
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           isActive
//                               ? 'VALID CERTIFICATE'
//                               : 'INVALID CERTIFICATE',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: isActive
//                                 ? AppTheme.secondary
//                                 : AppTheme.error,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           isActive
//                               ? 'This certificate is active and verified'
//                               : 'This certificate has been revoked',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: isActive
//                                 ? AppTheme.secondary
//                                 : AppTheme.error,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Certificate Details Card
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: AppTheme.outlineVariant),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Header
//                         const Center(
//                           child: Text(
//                             'CERTIFICATE OF GRADUATION',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),

//                         // Student Name
//                         _buildDetailRow(
//                           label: 'Student Name',
//                           value: _certificate?['studentName'] ?? 'Unknown',
//                         ),
//                         const SizedBox(height: 16),

//                         // Student ID
//                         _buildDetailRow(
//                           label: 'Student ID',
//                           value: _certificate?['studentId'] ?? 'Unknown',
//                         ),
//                         const SizedBox(height: 16),

//                         // Degree
//                         _buildDetailRow(
//                           label: 'Degree',
//                           value: _certificate?['degree'] ?? 'Unknown',
//                         ),
//                         const SizedBox(height: 16),

//                         // Institution
//                         _buildDetailRow(
//                           label: 'Institution',
//                           value: _certificate?['institution'] ?? 'Unknown',
//                         ),
//                         const SizedBox(height: 16),

//                         // Graduation Date
//                         _buildDetailRow(
//                           label: 'Graduation Date',
//                           value: _formatDate(
//                             _certificate?['graduationDate'] ?? '',
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Issued At
//                         _buildDetailRow(
//                           label: 'Issued At',
//                           value: _formatDateTime(
//                             _certificate?['issuedAt'] ?? '',
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Credential ID
//                         _buildDetailRow(
//                           label: 'Credential ID',
//                           value:
//                               _certificate?['credentialId'] ??
//                               widget.credentialId,
//                           isMonospace: true,
//                         ),

//                         const SizedBox(height: 20),

//                         // Divider
//                         const Divider(),
//                         const SizedBox(height: 16),

//                         // Footer
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: AppTheme.primary.withOpacity(0.05),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.security,
//                                 size: 20,
//                                 color: AppTheme.primary,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   'This certificate is verified on the CredChain Blockchain Network',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: AppTheme.onSurfaceVariant,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDetailRow({
//     required String label,
//     required String value,
//     bool isMonospace = false,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: 110,
//           child: Text(
//             label,
//             style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               fontFamily: isMonospace ? 'monospace' : null,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null || dateString.isEmpty) return 'Unknown';
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return dateString.split('T')[0];
//     }
//   }

//   String _formatDateTime(String? dateTimeString) {
//     if (dateTimeString == null || dateTimeString.isEmpty) return 'Unknown';
//     try {
//       final date = DateTime.parse(dateTimeString);
//       final localDate = date.toLocal();
//       return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
//           '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return dateTimeString;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class GraduateCertificatesScreen extends StatefulWidget {
  const GraduateCertificatesScreen({super.key});

  @override
  State<GraduateCertificatesScreen> createState() =>
      _GraduateCertificatesScreenState();
}

class _GraduateCertificatesScreenState extends State<GraduateCertificatesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _allCertificates = [];
  List<Map<String, dynamic>> _filteredCertificates = [];
  bool _isLoading = true;
  String? _error;

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

  Future<void> _fetchCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getGraduateCredentials();

    setState(() {
      _isLoading = false;
      if (true) {
        _allCertificates = result;
        _applyFilter();
      }
    });
  }

  Future<void> _refresh() async {
    await _fetchCertificates();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentId = authProvider.currentUser?.studentId ?? '';
    final activeCount = _allCertificates
        .where((c) => c['status'] == 'active')
        .length;
    final revokedCount = _allCertificates
        .where((c) => c['status'] == 'revoked')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
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
                          : 'No certificates found',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Student ID: $studentId',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.outline,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredCertificates.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cert = _filteredCertificates[index];
                  return _CertificateCard(
                    certificate: cert,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraduateCertificateDetailScreen(
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
}

class _CertificateCard extends StatelessWidget {
  final Map<String, dynamic> certificate;
  final VoidCallback onTap;

  const _CertificateCard({required this.certificate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = certificate['status'] == 'active';

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
                    certificate['degree'] ?? 'Unknown Degree',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    certificate['institution'] ?? 'Unknown Institution',
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
                        _formatDate(certificate['graduation_date'] ?? ''),
                        style: TextStyle(fontSize: 12, color: AppTheme.outline),
                      ),
                    ],
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

class GraduateCertificateDetailScreen extends StatefulWidget {
  final String credentialId;

  const GraduateCertificateDetailScreen({
    super.key,
    required this.credentialId,
  });

  @override
  State<GraduateCertificateDetailScreen> createState() =>
      _GraduateCertificateDetailScreenState();
}

class _GraduateCertificateDetailScreenState
    extends State<GraduateCertificateDetailScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _certificate;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCertificate();
  }

  Future<void> _fetchCertificate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getGraduateCredential(widget.credentialId);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _certificate = result;
      } else {
        _error = result['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _certificate?['status'] == 'active';

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCertificate,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isActive ? AppTheme.secondary : AppTheme.error)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isActive ? Icons.verified : Icons.cancel,
                          size: 80,
                          color: isActive ? AppTheme.secondary : AppTheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isActive
                              ? 'VALID CERTIFICATE'
                              : 'INVALID CERTIFICATE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AppTheme.secondary
                                : AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActive
                              ? 'This certificate is active and verified'
                              : 'This certificate has been revoked',
                          style: TextStyle(
                            fontSize: 14,
                            color: isActive
                                ? AppTheme.secondary
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Certificate Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'CERTIFICATE OF GRADUATION',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDetailRow(
                          'Student Name',
                          _certificate?['studentName'] ?? 'Unknown',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Student ID',
                          _certificate?['studentId'] ?? 'Unknown',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Degree',
                          _certificate?['degree'] ?? 'Unknown',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Institution',
                          _certificate?['institution'] ?? 'Unknown',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Graduation Date',
                          _formatDate(_certificate?['graduationDate'] ?? ''),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Issued At',
                          _formatDateTime(_certificate?['issuedAt'] ?? ''),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Credential ID',
                          _certificate?['credentialId'] ?? widget.credentialId,
                          isMonospace: true,
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'This certificate is verified on the CredChain Blockchain Network',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateTimeString);
      final localDate = date.toLocal();
      return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
          '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
