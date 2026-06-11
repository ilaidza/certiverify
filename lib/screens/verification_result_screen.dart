// import 'package:certiverify/screens/certificate_details_screen.dart';
// import 'package:certiverify/widgets/qr_scanner_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
// // import '../models/certificate.dart';
// import '../services/api_service.dart';
// import '../services/storage_service.dart';
// // import '../services/notification_service.dart';
// import '../utils/theme.dart';

// class VerificationResultScreen extends StatefulWidget {
//   final String credentialId;
//   final Map<String, dynamic>? verificationResult;

//   const VerificationResultScreen({
//     super.key,
//     required this.credentialId,
//     this.verificationResult,
//   });

//   @override
//   State<VerificationResultScreen> createState() =>
//       _VerificationResultScreenState();
// }

// class _VerificationResultScreenState extends State<VerificationResultScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;

//   final ApiService _apiService = ApiService();

//   // Certificate? _certificate;
//   bool _isLoading = true;
//   bool _isValid = false;
//   Map<String, dynamic>? _credentialDetails;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );

//     _verifyCertificate();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _verifyCertificate() async {
//     setState(() => _isLoading = true);

//     // Check if we already have verification result
//     if (widget.verificationResult != null &&
//         widget.verificationResult!['success']) {
//       final result = widget.verificationResult!;
//       _isValid = result['isValid'] ?? false;

//       if (_isValid) {
//         // Fetch full credential details
//         await _fetchCredentialDetails();
//       }

//       setState(() => _isLoading = false);
//       _animationController.forward();
//       return;
//     }

//     // Otherwise, verify with API
//     final result = await _apiService.verifyCredential(widget.credentialId);

//     if (result['success']) {
//       _isValid = result['isValid'];

//       if (_isValid) {
//         await _fetchCredentialDetails();
//       }

//       // Cache result for offline
//       await StorageService.saveRecentVerification(widget.credentialId);
//       // await NotificationService.showVerificationResult(
//       //   isValid: _isValid,
//       //   studentName: _credentialDetails?['studentName'] ?? '',
//       //   degree: _credentialDetails?['degree'] ?? '',
//       // );
//     } else {
//       _errorMessage = result['error'];
//     }

//     setState(() => _isLoading = false);
//     _animationController.forward();
//   }

//   Future<void> _fetchCredentialDetails() async {
//     final details = await _apiService.getCredentialDetails(widget.credentialId);
//     if (details['success']) {
//       _credentialDetails = details;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verification Result'),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: ScaleTransition(
//                       scale: _scaleAnimation,
//                       child: _isValid
//                           ? _buildSuccessWidget()
//                           : _buildFailureWidget(),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   if (_isValid && _credentialDetails != null)
//                     _buildCertificateCard(),
//                   const SizedBox(height: 24),
//                   _buildActionButtons(),
//                   const SizedBox(height: 16),
//                   _buildBlockchainProof(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildSuccessWidget() {
//     return Column(
//       children: [
//         Container(
//           width: 100,
//           height: 100,
//           decoration: BoxDecoration(
//             color: AppTheme.secondaryContainer.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(
//             Icons.verified,
//             size: 60,
//             color: AppTheme.secondary,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'CREDENTIAL VERIFIED',
//           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//             color: AppTheme.secondary,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 2,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'This certificate is authentic and valid',
//           style: TextStyle(color: AppTheme.secondary, fontSize: 14),
//         ),
//       ],
//     );
//   }

//   Widget _buildFailureWidget() {
//     return Column(
//       children: [
//         Container(
//           width: 100,
//           height: 100,
//           decoration: BoxDecoration(
//             color: AppTheme.errorContainer.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(Icons.gpp_bad, size: 60, color: AppTheme.error),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'VERIFICATION FAILED',
//           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//             color: AppTheme.error,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 2,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           _errorMessage ?? 'This credential could not be verified',
//           style: TextStyle(color: AppTheme.onSurfaceVariant),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildCertificateCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: AppTheme.outlineVariant),
//         boxShadow: [
//           BoxShadow(
//             color: AppTheme.primary.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppTheme.surface,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//               border: Border(
//                 bottom: BorderSide(color: AppTheme.outlineVariant),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: AppTheme.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(
//                     Icons.account_balance,
//                     color: AppTheme.primary,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _credentialDetails?['institutionName'] ?? 'Institution',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         'Office of the Registrar',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: AppTheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppTheme.secondaryContainer.withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.lock, size: 12, color: AppTheme.secondary),
//                       const SizedBox(width: 4),
//                       Text(
//                         'AUTHENTIC',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.secondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Body
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Student Name',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppTheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _credentialDetails?['studentName'] ?? 'Unknown',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Degree Awarded',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppTheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _credentialDetails?['degree'] ?? 'Unknown',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.primary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 if (_credentialDetails?['cgpa'] != null)
//                   Text(
//                     'CGPA: ${_credentialDetails?['cgpa']}',
//                     style: TextStyle(fontSize: 14, color: AppTheme.secondary),
//                   ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Student ID',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.onSurfaceVariant,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             _credentialDetails?['studentId'] ?? 'N/A',
//                             style: const TextStyle(fontWeight: FontWeight.w500),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             'Graduation Date',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.onSurfaceVariant,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             _formatDate(
//                               _credentialDetails?['graduationDate'] ?? '',
//                             ),
//                             style: const TextStyle(fontWeight: FontWeight.w500),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     if (!_isValid) {
//       return Row(
//         children: [
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       QRScannerWidget(onScanComplete: (String) {}),
//                 ),
//               ),
//               icon: const Icon(Icons.qr_code_scanner),
//               label: const Text('Scan Again'),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 // Report fraud
//               },
//               icon: const Icon(Icons.flag),
//               label: const Text('Report'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.error,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.qr_code_scanner),
//                 label: const Text('Scan Another'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () => _shareResult(),
//                 icon: const Icon(Icons.share),
//                 label: const Text('Share Result'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         ElevatedButton.icon(
//           onPressed: () {
//             if (_credentialDetails != null) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => CredentialDetailsScreen(
//                     credentialId: widget.credentialId,
//                   ),
//                 ),
//               );
//             }
//           },
//           icon: const Icon(Icons.visibility),
//           label: const Text('View Full Certificate Details'),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 14),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBlockchainProof() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.link, size: 18, color: AppTheme.primary),
//               const SizedBox(width: 8),
//               Text(
//                 'Blockchain Proof',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.primary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Credential ID',
//                       style: TextStyle(fontSize: 11, color: AppTheme.outline),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             widget.credentialId,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontFamily: 'monospace',
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.copy, size: 16),
//                           onPressed: () {
//                             Clipboard.setData(
//                               ClipboardData(text: widget.credentialId),
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Copied to clipboard'),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: AppTheme.primary.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.security, size: 16, color: AppTheme.primary),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'This record is verified on the CredChain blockchain network',
//                     style: TextStyle(fontSize: 10),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _shareResult() async {
//     // Share verification result
//     final message = _isValid
//         ? '✅ Certificate Verified!\n\n'
//               'Student: ${_credentialDetails?['studentName']}\n'
//               'Degree: ${_credentialDetails?['degree']}\n'
//               'Institution: ${_credentialDetails?['institutionName']}\n'
//               'Verified on CredChain Nigeria'
//         : '❌ Verification Failed\n\n'
//               'The certificate with ID ${widget.credentialId} could not be verified.\n'
//               'Please contact the issuing institution.';

//     await Share.share(message);
//   }

//   String _formatDate(String dateString) {
//     if (dateString.isEmpty) return 'N/A';
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return dateString.split('T')[0];
//     }
//   }

//   // void _shareResult() {
//   //   // Implement share functionality
//   // }
// }

import 'package:certiverify/screens/certificate_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class VerificationResultScreen extends StatefulWidget {
  final String credentialId;
  final Map<String, dynamic>? verificationResult;

  const VerificationResultScreen({
    super.key,
    required this.credentialId,
    this.verificationResult,
  });

  @override
  State<VerificationResultScreen> createState() =>
      _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();

  bool _isValid = false;
  String _status = '';
  String? _errorMessage;
  Map<String, dynamic>? _credentialDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _processVerificationResult();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processVerificationResult() async {
    setState(() => _isLoading = true);

    if (widget.verificationResult != null) {
      final result = widget.verificationResult!;

      if (result['success'] == false) {
        // ID not recognized
        _isValid = false;
        _errorMessage = result['error'] ?? 'Credential ID not recognized';
        _status = 'not_found';
      } else {
        _isValid = result['isValid'] ?? false;
        _status = result['status'] ?? 'unknown';

        if (result['credentialDetails'] != null) {
          _credentialDetails = result['credentialDetails'];
        } else if (_isValid && _status == 'active') {
          // Fetch full details for active credential
          final details = await _apiService.getCredentialDetails(
            widget.credentialId,
          );
          if (details['success']) {
            _credentialDetails = details;
          }
        }
      }

      setState(() => _isLoading = false);
      _animationController.forward();
      return;
    }

    // Fallback: Verify with API
    final result = await _apiService.verifyCredential(widget.credentialId);

    if (result['success']) {
      _isValid = result['isValid'];
      _status = result['status'] ?? 'active';

      if (_isValid) {
        final details = await _apiService.getCredentialDetails(
          widget.credentialId,
        );
        if (details['success']) {
          _credentialDetails = details;
        }
      }

      await StorageService.saveRecentVerification(widget.credentialId);
    } else {
      _isValid = false;
      _errorMessage = result['error'] ?? 'Credential not found';
      _status = 'not_found';
    }

    setState(() => _isLoading = false);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareResult),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildStatusWidget(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_status == 'active' && _credentialDetails != null)
                    _buildCertificateCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildBlockchainProof(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusWidget() {
    if (_status == 'not_found') {
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_mark,
              size: 60,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CREDENTIAL NOT RECOGNIZED',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'This credential ID does not exist in our system',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: ${widget.credentialId}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      );
    }

    if (_status == 'active') {
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              size: 60,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CREDENTIAL VALID',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This certificate is active and verified',
            style: TextStyle(color: AppTheme.secondary, fontSize: 14),
          ),
        ],
      );
    }

    if (_status == 'revoked') {
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, size: 60, color: AppTheme.error),
          ),
          const SizedBox(height: 16),
          Text(
            'CREDENTIAL REVOKED',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This certificate has been revoked by the institution',
            style: TextStyle(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_status == 'suspended') {
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_circle,
              size: 60,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CREDENTIAL SUSPENDED',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This certificate is temporarily suspended',
            style: const TextStyle(color: Colors.orange),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCertificateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _credentialDetails?['institutionName'] ?? 'Institution',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Office of the Registrar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'AUTHENTIC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Name',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _credentialDetails?['studentName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Degree Awarded',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _credentialDetails?['degree'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_credentialDetails?['cgpa'] != null)
                  Text(
                    'CGPA: ${_credentialDetails?['cgpa']}',
                    style: TextStyle(fontSize: 14, color: AppTheme.secondary),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _credentialDetails?['studentId'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Graduation Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(
                              _credentialDetails?['graduationDate'] ?? '',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_status == 'not_found') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _reportIssue(),
              icon: const Icon(Icons.flag),
              label: const Text('Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    if (_status == 'active') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareResult,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Result'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_credentialDetails != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CredentialDetailsScreen(
                        credentialId: widget.credentialId,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Full Certificate Details'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    // For revoked or suspended
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareResult,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainProof() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Blockchain Proof',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credential ID',
                      style: TextStyle(fontSize: 11, color: AppTheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.credentialId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.credentialId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This record is verified on the CredChain blockchain network',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareResult() async {
    String message;

    if (_status == 'not_found') {
      message =
          '❌ Verification Failed\n\n'
          'Credential ID: ${widget.credentialId}\n'
          'Status: Not recognized in the system\n'
          'Please contact the issuing institution.';
    } else if (_status == 'active') {
      message =
          '✅ Certificate Verified!\n\n'
          'Student: ${_credentialDetails?['studentName'] ?? 'N/A'}\n'
          'Degree: ${_credentialDetails?['degree'] ?? 'N/A'}\n'
          'Institution: ${_credentialDetails?['institutionName'] ?? 'N/A'}\n'
          'Status: ACTIVE\n'
          'Verified on CredChain Nigeria';
    } else if (_status == 'revoked') {
      message =
          '❌ Certificate Revoked\n\n'
          'Credential ID: ${widget.credentialId}\n'
          'Status: REVOKED\n'
          'This certificate is no longer valid.';
    } else {
      message =
          '⚠️ Certificate Suspended\n\n'
          'Credential ID: ${widget.credentialId}\n'
          'Status: SUSPENDED\n'
          'This certificate is temporarily unavailable.';
    }

    await Share.share(message);
  }

  void _reportIssue() {
    // Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted to support')),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }
}
