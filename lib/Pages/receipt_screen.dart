// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_helper.dart';
import '../utils/formatters.dart';

class ReceiptScreen extends ConsumerWidget {
  final String name;
  final String department;
  final String level;
  final String matric;
  final String feeType;
  final String amount;
  final String receiptNumber;
  final String qrData;
  final String bankName;
  final String accountNumber;

  const ReceiptScreen({
    super.key,
    required this.name,
    required this.department,
    required this.level,
    required this.matric,
    required this.feeType,
    required this.amount,
    required this.receiptNumber,
    required this.qrData,
    required this.bankName,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _downloadReceiptAsPdf(context),
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download PDF',
          ),
          IconButton(
            onPressed: () => _shareReceipt(context),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Receipt',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsiveMargin(context),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getCardWidth(context),
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsivePadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildReceiptDetails(context),
                      const SizedBox(height: 32),
                      _buildQRCode(context),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 40,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Payment Successful',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Oduduwa University',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Official Payment Receipt',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReceiptDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildReceiptItem(context, 'Receipt Number', receiptNumber, isHighlighted: true),
          const Divider(height: 24),
          _buildReceiptItem(context, 'Student Name', name),
          _buildReceiptItem(context, 'Matric Number', matric),
          _buildReceiptItem(context, 'Department', department),
          _buildReceiptItem(context, 'Level/Year', level),
          const Divider(height: 24),
          _buildReceiptItem(context, 'Fee Type', feeType),
          _buildReceiptItem(context, 'Bank Name', bankName),
          _buildReceiptItem(context, 'Account Number', accountNumber),
          _buildReceiptItem(context, 'Amount Paid', '₦$amount', isAmount: true),
          _buildReceiptItem(context, 'Payment Date', Formatters.formatDateTime(DateTime.now())),
          _buildReceiptItem(context, 'Status', 'Completed', isStatus: true),
        ],
      ),
    );
  }

  Widget _buildReceiptItem(
    BuildContext context,
    String title,
    String value, {
    bool isHighlighted = false,
    bool isAmount = false,
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isHighlighted || isAmount ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted
                        ? Theme.of(context).primaryColor
                        : isAmount || isStatus
                            ? Colors.green
                            : null,
                    fontSize: isAmount ? 16 : null,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(BuildContext context) {
    return Column(
      children: [
        Text(
          'Scan to Verify',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: context.isMobile ? 150 : 200,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return context.isMobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadReceiptAsPdf(context),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareReceipt(context),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Receipt'),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadReceiptAsPdf(context),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareReceipt(context),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Receipt'),
                ),
              ),
            ],
          );
  }

  Future<void> _downloadReceiptAsPdf(BuildContext context) async {
    final doc = pw.Document();
    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
    );
    final qrImage = await qrPainter.toImageData(200);
    final ByteData bytes = await rootBundle.load('assets/images/school_logo.png');
    final Uint8List logo = bytes.buffer.asUint8List();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
                pw.Image(pw.MemoryImage(logo), height: 80), 
                pw.Text(
                  'Oduduwa University\nOfficial Payment Receipt',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              
              pw.SizedBox(height: 20),
              _buildPdfReceiptItem('Receipt Number', receiptNumber),
              _buildPdfReceiptItem('Student Name', name),
              _buildPdfReceiptItem('Matric Number', matric),
              _buildPdfReceiptItem('Department', department),
              _buildPdfReceiptItem('Level/Year', level),
              _buildPdfReceiptItem('Fee Type', feeType),
              _buildPdfReceiptItem('Bank Name', bankName),
              _buildPdfReceiptItem('Account Number', accountNumber),
              _buildPdfReceiptItem('Amount Paid', '₦$amount'),
              _buildPdfReceiptItem('Payment Date', Formatters.formatDateTime(DateTime.now())),
              _buildPdfReceiptItem('Status', 'Completed'),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Scan to Verify'),
                    pw.SizedBox(height: 10),
                    if (qrImage != null)
                      pw.Image(
                        pw.MemoryImage(qrImage.buffer.asUint8List()),
                        width: 100,
                        height: 100,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Receipt_$receiptNumber.pdf',
    );
  }

  pw.Widget _buildPdfReceiptItem(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$title:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
      ),
    );
  }
}
