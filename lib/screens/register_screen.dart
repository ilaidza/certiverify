import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Institution Admin fields
  final _institutionNameController = TextEditingController();
  final _institutionCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _adminNameController = TextEditingController();

  // Verifier fields
  final _verifierNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _verifierPhoneController = TextEditingController();

  // Graduate fields
  final _graduateFullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  // String _InstitutionName = TextEditingController() as String;

  String _userType = 'institution'; // 'institution', 'verifier', 'graduate'
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Institution codes for dropdown
  // final List<Map<String, String>> _institutions = [
  //   {'code': 'UNILAG', 'name': 'University of Lagos'},
  //   {'code': 'UNN', 'name': 'University of Nigeria, Nsukka'},
  //   {'code': 'OAU', 'name': 'Obafemi Awolowo University'},
  //   {'code': 'ABU', 'name': 'Ahmadu Bello University'},
  //   {'code': 'UI', 'name': 'University of Ibadan'},
  //   {'code': 'FUTA', 'name': 'Federal University of Technology, Akure'},
  //   {'code': 'UNIBEN', 'name': 'University of Benin'},
  //   {'code': 'UNIMAID', 'name': 'University of Maiduguri'},
  //   {'code': 'TEST', 'name': 'Test University FUTA'},
  //   {'code': 'Other', 'name': 'Other Institution'},
  // ];

  // Generate timestamp for unique test data
  String get _timestamp =>
      DateTime.now().millisecondsSinceEpoch.toString().substring(8);

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _institutionNameController.dispose();
    _institutionCodeController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _adminNameController.dispose();
    _verifierNameController.dispose();
    _organizationController.dispose();
    _verifierPhoneController.dispose();
    _graduateFullNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _fillTestData() {
    final timestamp = _timestamp;

    if (_userType == 'institution') {
      setState(() {
        _emailController.text = 'admin_test_${timestamp}@university.edu.ng';
        _passwordController.text = 'Test1234!';
        _confirmPasswordController.text = 'Test1234!';
        _institutionNameController.text = 'Test University ${timestamp}';
        _institutionCodeController.text = 'TEST${timestamp}';
        _addressController.text = '123 Test Street, Lagos';
        _contactEmailController.text = 'info@testuni.edu.ng';
        _contactPhoneController.text = '+2341234567890';
        _adminNameController.text = 'Dr. John Admin';
      });
    } else if (_userType == 'verifier') {
      setState(() {
        _emailController.text = 'verifier_${timestamp}@company.com';
        _passwordController.text = 'Test1234!';
        _confirmPasswordController.text = 'Test1234!';
        _verifierNameController.text = 'John Verifier';
        _organizationController.text = 'Test Corp';
        _verifierPhoneController.text = '+1234567890';
      });
    } else {
      setState(() {
        _emailController.text = '${timestamp}@student.com';
        _passwordController.text = 'Test1234!';
        _confirmPasswordController.text = 'Test1234!';
        _graduateFullNameController.text = '${timestamp}';
        _studentIdController.text =
            'CSC/20/4835'; // This matches the issued credential student_id
        _institutionNameController.text =
            'Test1234!'
            'TEST UNIVERSITY FUTA'; // This matches the issued credential institution_name
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_userType == 'institution') {
      result = await _apiService.registerInstitution(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        institutionName: _institutionNameController.text.trim(),
        institutionCode: _institutionCodeController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        adminName: _adminNameController.text.trim(),
      );
    } else if (_userType == 'verifier') {
      result = await _apiService.registerVerifier(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        name: _verifierNameController.text.trim(),
        organization: _organizationController.text.trim(),
        contactPhone: _verifierPhoneController.text.trim(),
      );
    } else {
      result = await _apiService.registerGraduate(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        fullName: _graduateFullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        institutionCode: _institutionNameController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      _showSuccessDialog(result);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Registration failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.secondary, size: 15),
            const SizedBox(width: 12),
            const Text(
              'Registration Successful!',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(result['message']),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result['userId'] != null)
                      _buildInfoRow('User ID', result['userId']),
                    if (result['email'] != null)
                      _buildInfoRow('Email', result['email']),
                    if (result['institutionName'] != null)
                      _buildInfoRow('Institution', result['institutionName']),
                    if (result['name'] != null)
                      _buildInfoRow('Name', result['name']),
                    if (result['organization'] != null)
                      _buildInfoRow('Organization', result['organization']),
                    if (result['role'] != null)
                      _buildInfoRow(
                        'Role',
                        result['role'].toString().toUpperCase(),
                      ),
                  ],
                ),
              ),
              if (_userType == 'graduate' &&
                  result['code'] == 'STUDENT_NOT_FOUND')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, size: 20, color: AppTheme.error),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Note: No credential found for this Student ID. Please contact your institution to issue your certificate first.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_userType == 'graduate' && result['success']) ...[
                if (result['graduationDate'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildInfoRow(
                      'Graduation Date',
                      _formatDate(result['graduationDate']),
                    ),
                  ),
                if (result['institutionName'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildInfoRow(
                      'Institution',
                      result['institutionName'],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add, size: 28, color: AppTheme.primary),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register New Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose your account type below',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // User Type Selection
            const Text(
              'Account Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Row for first two cards
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    title: 'Institution',
                    description: 'University, Polytechnic',
                    icon: Icons.account_balance,
                    isSelected: _userType == 'institution',
                    onTap: () {
                      setState(() => _userType = 'institution');
                      _fillTestData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserTypeCard(
                    title: 'Verifier',
                    description: 'Employer, Company',
                    icon: Icons.business,
                    isSelected: _userType == 'verifier',
                    onTap: () {
                      setState(() => _userType = 'verifier');
                      _fillTestData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Third card takes full width (not inside Row with Expanded)
            _buildUserTypeCard(
              title: 'Graduate',
              description: 'Student Registration',
              icon: Icons.school,
              isSelected: _userType == 'graduate',
              onTap: () {
                setState(() => _userType = 'graduate');
                _fillTestData();
              },
            ),

            const SizedBox(height: 24),

            // Registration Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Common Fields: Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Institution Admin Fields
                  if (_userType == 'institution') ...[
                    TextFormField(
                      controller: _institutionNameController,
                      decoration: const InputDecoration(
                        labelText: 'Institution Name *',
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter institution name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _institutionCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Institution Code *',
                        prefixIcon: Icon(Icons.code),
                        hintText: 'e.g. UNILAG, OAU, UNN',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter institution code'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email *',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter contact email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter contact phone' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adminNameController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter admin name' : null,
                    ),
                  ],

                  // Verifier Fields
                  if (_userType == 'verifier') ...[
                    TextFormField(
                      controller: _verifierNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization/Company *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter organization' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _verifierPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter contact phone' : null,
                    ),
                  ],

                  // Graduate Fields
                  if (_userType == 'graduate') ...[
                    TextFormField(
                      controller: _graduateFullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'e.g. Jane Graduate',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID *',
                        prefixIcon: Icon(Icons.numbers),
                        hintText: 'e.g. STUjane, CSC/20/4835',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your Student ID'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _institutionNameController,
                      decoration: const InputDecoration(
                        labelText: 'Institution *',
                        prefixIcon: Icon(Icons.school),
                        hintText:
                            'e.g. Federal University of Technology, Akure',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your Institution'
                          : null,
                    ),
                    // const SizedBox(height: 16),
                    // DropdownButtonFormField<String>(
                    //   value: _selectedInstitutionCode.isEmpty
                    //       ? null
                    //       : _selectedInstitutionCode,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Institution *',
                    //     prefixIcon: Icon(Icons.school),
                    //   ),
                    //   items: _institutions.map((inst) {
                    //     return DropdownMenuItem(
                    //       value: inst['code'],
                    //       child: Text('${inst['code']} - ${inst['name']}'),
                    //     );
                    //   }).toList(),
                    //   onChanged: (value) =>
                    //       setState(() => _selectedInstitutionCode = value!),
                    //   validator: (value) => value == null
                    //       ? 'Please select your institution'
                    //       : null,
                    // ),
                    // Info box about existing credential
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your Student ID must match a credential issued by your institution. The certificate will be linked to your account upon registration.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a password';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) =>
                            setState(() => _agreeToTerms = value!),
                        activeColor: AppTheme.primary,
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms and Conditions and Privacy Policy',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test Data Button
                  OutlinedButton.icon(
                    onPressed: _fillTestData,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Fill Test Data'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
