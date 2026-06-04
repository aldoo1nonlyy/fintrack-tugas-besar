import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/financial_entry.dart';
import '../providers/app_data_provider.dart';

class FinancePdfService {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  static Future<void> exportFinancialReport(AppDataProvider provider) async {
    final bytes = await _buildFinancialReport(provider);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'laporan-keuangan-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> _buildFinancialReport(AppDataProvider provider) async {
    final summary = provider.financialSummary;
    final entries = provider.combinedFinancialEntries;
    final profile = provider.businessProfile;
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(profile.address),
                  pw.Text(profile.phone),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Laporan Keuangan',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(_dateFormat.format(DateTime.now())),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _summaryBox('Saldo', summary.balance, PdfColors.blue),
              pw.SizedBox(width: 8),
              _summaryBox('Pemasukan', summary.income, PdfColors.green),
              pw.SizedBox(width: 4),
              _summaryBox('Pengeluaran', summary.expense, PdfColors.red),
              pw.SizedBox(width: 4),
              _summaryBox('Piutang', summary.receivable, PdfColors.blue),
              pw.SizedBox(width: 4),
              _summaryBox('Hutang', summary.payable, PdfColors.orange),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'Perhitungan otomatis: saldo = pemasukan - pengeluaran. Proyeksi total = saldo + piutang - hutang = ${_currency.format(summary.projectedBalance)}.',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Rincian Keuangan',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Tanggal', 'Jenis', 'Sumber', 'Keterangan', 'Nominal'],
              ...entries.map(
                (entry) => [
                  _dateFormat.format(entry.date),
                  entry.type.label,
                  entry.sourceLabel,
                  entry.title,
                  _currency.format(entry.amount),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _summaryBox(String title, double value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text(
              _currency.format(value),
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
