import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/certificate.dart';

class PDFService {
  /// Generate a beautiful certificate PDF
  static Future<Uint8List> generateCertificatePDF({
    required Certificate certificate,
    required Uint8List qrCodeImage,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header with institution seal placeholder
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
                      child: pw.Text('🏛️', style: pw.TextStyle(fontSize: 40)),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        certificate.institution,
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
                certificate.studentName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Matric Number: ${certificate.matricNumber}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'has successfully completed the requirements for',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                certificate.degree,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                certificate.classification,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'from',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                certificate.institution,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 40),

              pw.Text(
                'Issued on: ${certificate.issueDate}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),

              pw.SizedBox(height: 30),

              // QR Code
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
                      pw.Text('Registrar', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('_____________________'),
                      pw.Text(
                        'Vice-Chancellor',
                        style: pw.TextStyle(fontSize: 10),
                      ),
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
                      'Verified on CredChain Blockchain • ${certificate.transactionId.substring(0, 16)}...',
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

  /// Save PDF to device
  static Future<File?> savePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  /// Share PDF
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here is my verified certificate from CredChain Nigeria');
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  /// Print PDF
  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}
