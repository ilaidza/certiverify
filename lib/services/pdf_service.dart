import 'dart:io';
import 'dart:typed_data';
import 'package:certiverify/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFService {
  /// Generate a beautiful certificate PDF
  static Future<Uint8List> generateCertificatePDF({
    required Map<String, dynamic> credential,
    required Uint8List? qrCodeImage,
  }) async {
    final pdf = pw.Document();

    // Format dates
    final issuedAt = _formatDate(
      credential['issuedAt'] ?? credential['issued_at'] ?? '',
    );
    final graduationDate = _formatDate(
      credential['graduationDate'] ?? credential['graduation_date'] ?? '',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with institution seal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(40),
                    ),
                    child: pw.Center(
                      child: pw.Icon(
                        pw.IconData(0xe3c5),
                        size: 40,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        credential['institutionName'] ??
                            credential['institution_name'] ??
                            'University',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Office of the Registrar',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Title
              pw.Text(
                'CERTIFICATE OF GRADUATION',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 20),

              // Divider
              pw.Container(height: 2, color: PdfColors.blue900, width: 100),

              pw.SizedBox(height: 40),

              // Body text
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                (credential['studentName'] ??
                        credential['student_name'] ??
                        'Student Name')
                    .toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Student ID: ${credential['studentId'] ?? credential['student_id'] ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'has successfully completed the requirements for',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                credential['degree'] ?? 'Degree',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 8),

              if (credential['cgpa'] != null &&
                  credential['cgpa'].toString().isNotEmpty)
                pw.Text(
                  'CGPA: ${credential['cgpa']}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

              pw.SizedBox(height: 24),

              pw.Text(
                'from',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                credential['institutionName'] ??
                    credential['institution_name'] ??
                    'Institution',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 40),

              pw.Text(
                'Graduated on: $graduationDate',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),

              pw.SizedBox(height: 30),

              // QR Code
              if (qrCodeImage != null)
                pw.Container(
                  width: 120,
                  height: 120,
                  child: pw.Image(pw.MemoryImage(qrCodeImage)),
                ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Scan QR code to verify authenticity',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),

              pw.SizedBox(height: 20),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('_____________________'),
                      pw.Text(
                        'Vice-Chancellor',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('_____________________'),
                      pw.Text('Registrar', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Blockchain footer
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('🔗 ', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      'Verified on CredChain Blockchain • ${(credential['credentialId'] ?? credential['credential_id'] ?? '').substring(0, 16)}...',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Save PDF to Downloads folder (visible in File Manager)
  static Future<File?> saveToDownloads({
    required Uint8List pdfBytes,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      // Request storage permission if needed
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission required to save PDFs'),
              ),
            );
          }
          return null;
        }
      }

      // For Android 10+ (API 29+), use Downloads folder
      final directory = await getDownloadsDirectory();

      if (directory != null) {
        final fileNameWithExt = fileName.endsWith('.pdf')
            ? fileName
            : '$fileName.pdf';
        final file = File('${directory.path}/$fileNameWithExt');
        await file.writeAsBytes(pdfBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF saved to Downloads/${file.path.split('/').last}',
              ),
              backgroundColor: AppTheme.secondary,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        return file;
      }
      return null;
    } catch (e) {
      print('Error saving PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving PDF')));
      }
      return null;
    }
  }

  /// Save PDF to custom directory (creates a CertiVerify folder)
  static Future<File?> saveToCustomDirectory({
    required Uint8List pdfBytes,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      // Request storage permission if needed
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission required to save PDFs'),
              ),
            );
          }
          return null;
        }
      }

      // Get external storage directory
      final directory = await getExternalStorageDirectory();

      if (directory != null) {
        // Create a CertiVerify folder
        final certiverifyDir = Directory('${directory.path}/CertiVerify');
        if (!await certiverifyDir.exists()) {
          await certiverifyDir.create(recursive: true);
        }

        final fileNameWithExt = fileName.endsWith('.pdf')
            ? fileName
            : '$fileName.pdf';
        final file = File('${certiverifyDir.path}/$fileNameWithExt');
        await file.writeAsBytes(pdfBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF saved to ${certiverifyDir.path}/$fileNameWithExt',
              ),
              backgroundColor: AppTheme.secondary,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        return file;
      }
      return null;
    } catch (e) {
      print('Error saving PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving PDF')));
      }
      return null;
    }
  }

  /// Save and share PDF
  static Future<void> saveAndSharePDF({
    required Uint8List pdfBytes,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here is the official certificate from CredChain Nigeria');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF ready to share!')));
      }
    } catch (e) {
      print('Error sharing PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error generating PDF')));
      }
    }
  }

  /// Save PDF with options dialog (Save to Downloads / Share / Copy to CertiVerify)
  static Future<void> showSaveOptionsDialog({
    required Uint8List pdfBytes,
    required String fileName,
    required BuildContext context,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Save Certificate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Save to Downloads'),
              subtitle: const Text('Accessible in your File Manager'),
              onTap: () async {
                Navigator.pop(context);
                await saveToDownloads(
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: const Text('Save to CertiVerify Folder'),
              subtitle: const Text(
                'Creates a dedicated folder for your certificates',
              ),
              onTap: () async {
                Navigator.pop(context);
                await saveToCustomDirectory(
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share'),
              subtitle: const Text('Share via WhatsApp, Email, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await saveAndSharePDF(
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                  context: context,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }
}
