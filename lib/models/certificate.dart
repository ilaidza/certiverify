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
  final String status; // ACTIVE, REVOKED
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

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'],
    transactionId: json['transactionId'],
    hash: json['hash'],
    studentName: json['studentName'],
    matricNumber: json['matricNumber'],
    degree: json['degree'],
    institution: json['institution'],
    institutionId: json['institutionId'],
    issueDate: json['issueDate'],
    graduationDate: json['graduationDate'],
    classification: json['classification'],
    status: json['status'],
    revocationReason: json['revocationReason'],
    issuedAt: DateTime.parse(json['issuedAt']),
    lastVerified: json['lastVerified'] != null
        ? DateTime.parse(json['lastVerified'])
        : null,
    verificationCount: json['verificationCount'],
  );

  // bool get isActive => status == 'ACTIVE';
  // bool get isRevoked => status == 'REVOKED';
  bool get isActive => status == 'ACTIVE' || status == 'active';
  bool get isRevoked => status == 'REVOKED' || status == 'revoked';

  String get truncatedTransactionId =>
      '${transactionId.substring(0, 8)}...${transactionId.substring(transactionId.length - 4)}';
  String get truncatedHash =>
      '${hash.substring(0, 16)}...${hash.substring(hash.length - 8)}';
}
