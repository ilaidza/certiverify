import 'package:flutter/material.dart';
import '../utils/theme.dart';

class InstitutionsScreen extends StatefulWidget {
  const InstitutionsScreen({super.key});

  @override
  State<InstitutionsScreen> createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends State<InstitutionsScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _institutions = [
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

          // Map view toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Map View'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Institutions grid
          Expanded(
            child: _filteredInstitutions.isEmpty
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
                          childAspectRatio:
                              0.9, // Changed from 1.1 to 0.9 for more height
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _filteredInstitutions.length,
                    itemBuilder: (context, index) {
                      final institution = _filteredInstitutions[index];
                      return _InstitutionCard(institution: institution);
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

  const _InstitutionCard({required this.institution});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to institution details
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Important: Use min size
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                institution['logo'],
                size: 28,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Institution Name
            Text(
              institution['name'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                color: AppTheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(institution['certificatesIssued'] / 1000).toStringAsFixed(1)}K issued',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
