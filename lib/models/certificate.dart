// class Certificate {
//   final String id;
//   final String transactionId;
//   final String hash;
//   final String studentName;
//   final String matricNumber;
//   final String degree;
//   final String institution;
//   final String institutionId;
//   final String issueDate;
//   final String? graduationDate;
//   final String classification;
//   final String status; // ACTIVE, REVOKED
//   final String? revocationReason;
//   final DateTime issuedAt;
//   final DateTime? lastVerified;
//   final int verificationCount;

//   Certificate({
//     required this.id,
//     required this.transactionId,
//     required this.hash,
//     required this.studentName,
//     required this.matricNumber,
//     required this.degree,
//     required this.institution,
//     required this.institutionId,
//     required this.issueDate,
//     this.graduationDate,
//     required this.classification,
//     this.status = 'ACTIVE',
//     this.revocationReason,
//     required this.issuedAt,
//     this.lastVerified,
//     this.verificationCount = 0,
//   });

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'transactionId': transactionId,
//     'hash': hash,
//     'studentName': studentName,
//     'matricNumber': matricNumber,
//     'degree': degree,
//     'institution': institution,
//     'institutionId': institutionId,
//     'issueDate': issueDate,
//     'graduationDate': graduationDate,
//     'classification': classification,
//     'status': status,
//     'revocationReason': revocationReason,
//     'issuedAt': issuedAt.toIso8601String(),
//     'lastVerified': lastVerified?.toIso8601String(),
//     'verificationCount': verificationCount,
//   };

//   factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
//     id: json['id'],
//     transactionId: json['transactionId'],
//     hash: json['hash'],
//     studentName: json['studentName'],
//     matricNumber: json['matricNumber'],
//     degree: json['degree'],
//     institution: json['institution'],
//     institutionId: json['institutionId'],
//     issueDate: json['issueDate'],
//     graduationDate: json['graduationDate'],
//     classification: json['classification'],
//     status: json['status'],
//     revocationReason: json['revocationReason'],
//     issuedAt: DateTime.parse(json['issuedAt']),
//     lastVerified: json['lastVerified'] != null
//         ? DateTime.parse(json['lastVerified'])
//         : null,
//     verificationCount: json['verificationCount'],
//   );

//   // bool get isActive => status == 'ACTIVE';
//   // bool get isRevoked => status == 'REVOKED';
//   bool get isActive => status == 'ACTIVE' || status == 'active';
//   bool get isRevoked => status == 'REVOKED' || status == 'revoked';

//   String get truncatedTransactionId =>
//       '${transactionId.substring(0, 8)}...${transactionId.substring(transactionId.length - 4)}';
//   String get truncatedHash =>
//       '${hash.substring(0, 16)}...${hash.substring(hash.length - 8)}';
// }

class Certificate {
  final String id;
  final String transactionId;
  final String hash;
  final String studentName;
  final String matricNumber;
  final String degree;
  final String institution;
  final String institutionId;
  final String issueDate;
  final String? graduationDate;
  final String classification;
  final String status;
  final String? revocationReason;
  final DateTime issuedAt;
  final DateTime? lastVerified;
  final int verificationCount;

  Certificate({
    required this.id,
    required this.transactionId,
    required this.hash,
    required this.studentName,
    required this.matricNumber,
    required this.degree,
    required this.institution,
    required this.institutionId,
    required this.issueDate,
    this.graduationDate,
    required this.classification,
    this.status = 'ACTIVE',
    this.revocationReason,
    required this.issuedAt,
    this.lastVerified,
    this.verificationCount = 0,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    // Handle both nested and flat structures
    final credential = json['credential'] ?? json;

    return Certificate(
      id: credential['credential_id'] ?? credential['id'] ?? '',
      transactionId: credential['tx_id'] ?? credential['transaction_id'] ?? '',
      hash: credential['hash'] ?? '',
      studentName:
          credential['student_name'] ?? credential['studentName'] ?? '',
      matricNumber:
          credential['student_id'] ??
          credential['matric_number'] ??
          credential['studentId'] ??
          '',
      degree: credential['degree'] ?? '',
      institution:
          credential['institution_name'] ??
          credential['institution'] ??
          'Unknown Institution',
      institutionId:
          credential['institution_id'] ?? credential['institutionId'] ?? '',
      issueDate: _formatDateFromApi(
        credential['issued_at'] ?? credential['issueDate'] ?? '',
      ),
      graduationDate: credential['graduation_date'] != null
          ? _formatDateFromApi(credential['graduation_date'])
          : null,
      classification:
          credential['degree_class'] ??
          credential['classification'] ??
          'Not Specified',
      status: (credential['status'] ?? 'active').toString().toUpperCase(),
      revocationReason: credential['revocation_reason'],
      issuedAt: _parseDateTime(
        credential['issued_at'] ??
            credential['issuedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      lastVerified: credential['last_verified'] != null
          ? _parseDateTime(credential['last_verified'])
          : null,
      verificationCount:
          credential['verification_count'] ?? credential['verifications'] ?? 0,
    );
  }

  static String _formatDateFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  static DateTime _parseDateTime(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'hash': hash,
    'studentName': studentName,
    'matricNumber': matricNumber,
    'degree': degree,
    'institution': institution,
    'institutionId': institutionId,
    'issueDate': issueDate,
    'graduationDate': graduationDate,
    'classification': classification,
    'status': status,
    'revocationReason': revocationReason,
    'issuedAt': issuedAt.toIso8601String(),
    'lastVerified': lastVerified?.toIso8601String(),
    'verificationCount': verificationCount,
  };

  bool get isActive => status == 'ACTIVE' || status == 'active';
  bool get isRevoked => status == 'REVOKED' || status == 'revoked';
  bool get isSuspended => status == 'SUSPENDED' || status == 'suspended';

  String get truncatedTransactionId => transactionId.length > 16
      ? '${transactionId.substring(0, 8)}...${transactionId.substring(transactionId.length - 4)}'
      : transactionId;

  String get truncatedHash => hash.length > 24
      ? '${hash.substring(0, 16)}...${hash.substring(hash.length - 8)}'
      : hash;
}
