import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class InstitutionsScreen extends StatefulWidget {
  const InstitutionsScreen({super.key});

  @override
  State<InstitutionsScreen> createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends State<InstitutionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _institutions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInstitutions();
  }

  Future<void> _fetchInstitutions() async {
    setState(() => _isLoading = true);

    // For now, use mock data since there's no specific endpoint
    // You can replace with actual API call when available
    await Future.delayed(const Duration(milliseconds: 500));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentInstitution = authProvider.currentUser?.institutionName;

    setState(() {
      _institutions = [
        {
          'id': 'UNILAG',
          'name': 'University of Lagos',
          'location': 'Akoka, Lagos',
          'certificatesIssued': 12450,
          'status': 'active',
          'logo': Icons.account_balance,
        },
        {
          'id': 'UNN',
          'name': 'University of Nigeria, Nsukka',
          'location': 'Nsukka, Enugu',
          'certificatesIssued': 9870,
          'status': 'active',
          'logo': Icons.account_balance,
        },
        {
          'id': 'OAU',
          'name': 'Obafemi Awolowo University',
          'location': 'Ile-Ife, Osun',
          'certificatesIssued': 11230,
          'status': 'active',
          'logo': Icons.account_balance,
        },
        {
          'id': 'ABU',
          'name': 'Ahmadu Bello University',
          'location': 'Zaria, Kaduna',
          'certificatesIssued': 10340,
          'status': 'active',
          'logo': Icons.account_balance,
        },
        {
          'id': 'FUTA',
          'name': 'Federal University of Technology, Akure',
          'location': 'Akure, Ondo',
          'certificatesIssued': 7650,
          'status': 'active',
          'logo': Icons.account_balance,
        },
        {
          'id': 'UI',
          'name': 'University of Ibadan',
          'location': 'Ibadan, Oyo',
          'certificatesIssued': 14280,
          'status': 'active',
          'logo': Icons.account_balance,
        },
      ];

      // Highlight current user's institution if available
      if (currentInstitution != null) {
        for (var i = 0; i < _institutions.length; i++) {
          if (_institutions[i]['name'] == currentInstitution) {
            _institutions[i]['isCurrent'] = true;
          }
        }
      }

      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredInstitutions {
    if (_searchQuery.isEmpty) return _institutions;
    return _institutions
        .where(
          (inst) =>
              inst['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              inst['location'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userInstitution = authProvider.currentUser?.institutionName;

    return Scaffold(
      appBar: AppBar(title: const Text('Registered Institutions')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search institutions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineVariant),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Institutions grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInstitutions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 80,
                          color: AppTheme.outline,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No institutions found',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _filteredInstitutions.length,
                    itemBuilder: (context, index) {
                      final institution = _filteredInstitutions[index];
                      final isCurrentUserInstitution =
                          userInstitution == institution['name'];

                      return _InstitutionCard(
                        institution: institution,
                        isHighlighted: isCurrentUserInstitution,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final Map<String, dynamic> institution;
  final bool isHighlighted;

  const _InstitutionCard({
    required this.institution,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show institution details dialog
        _showInstitutionDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppTheme.primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? AppTheme.primary : AppTheme.outlineVariant,
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isHighlighted ? AppTheme.primary : AppTheme.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                institution['logo'],
                size: 28,
                color: isHighlighted ? AppTheme.primary : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Institution Name
            Text(
              institution['name'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? AppTheme.primary : AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Location
            Text(
              institution['location'],
              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Stats badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isHighlighted ? AppTheme.primary : AppTheme.secondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(institution['certificatesIssued'] / 1000).toStringAsFixed(1)}K issued',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? AppTheme.primary : AppTheme.secondary,
                ),
              ),
            ),
            if (isHighlighted)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Your Institution',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showInstitutionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(institution['logo'], color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                institution['name'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Location', institution['location']),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Total Certificates',
              '${institution['certificatesIssued']}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Status',
              institution['status'].toString().toUpperCase(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
