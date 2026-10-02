import 'dart:convert';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/report_models.dart';

/// Builds every PDF the app can export. Views call these to get raw bytes,
/// then hand them to `Printing.sharePdf` (see the `printing` package) to
/// trigger a download or share sheet — this file never touches the UI.
class PdfService {
  PdfService._();

  // Same ink/muted tones as core/theme.dart, expressed as 0-1 RGB so they
  // can be `const PdfColor`s.
  static const _ink = PdfColor(0.078, 0.129, 0.239);
  static const _muted = PdfColor(0.420, 0.478, 0.561);

  // ---------------------------------------------------------------------
  // Employee ID card
  // ---------------------------------------------------------------------

  /// A card-shaped PDF (CR80 size, like a real ID) with the employee's
  /// photo-less details on one side and their check-in QR on the other.
  static Future<Uint8List> buildEmployeeIdCard(AppUser user) async {
    final doc = pw.Document();
    final format = PdfPageFormat(
      85.6 * PdfPageFormat.mm,
      54 * PdfPageFormat.mm,
      marginAll: 0,
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _ink, width: 1.2),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(color: _ink),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'EMPLOYEE ID',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.Text(
                      user.department.isEmpty ? ' ' : user.department,
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _photoBox(user.photoBase64, user.initials),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              user.fullName,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              user.position,
                              style: pw.TextStyle(fontSize: 7, color: _muted),
                            ),
                            pw.SizedBox(height: 5),
                            _line('ID', user.uid.substring(0, 8).toUpperCase()),
                            _line('Email', user.email),
                            _line('Phone', user.phone),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: '${AppConstants.qrPrefix}${user.qrToken}',
                              width: 56,
                              height: 56,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Scan to check in',
                              style: pw.TextStyle(fontSize: 6, color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// Rendered photo if present, otherwise the employee's initials — avoids
  /// depending on an icon font being embedded in the PDF.
  static pw.Widget _photoBox(String? photoBase64, String initials) {
    const size = 40.0;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      Uint8List bytes;
      try {
        bytes = base64Decode(photoBase64);
      } catch (_) {
        bytes = Uint8List(0);
      }
      if (bytes.isNotEmpty) {
        return pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(
            pw.MemoryImage(bytes),
            width: size,
            height: size,
            fit: pw.BoxFit.cover,
          ),
        );
      }
    }
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Center(
        child: pw.Text(
          initials,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );
  }

  static pw.Widget _line(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontSize: 7, color: _muted),
              ),
              pw.TextSpan(
                text: value,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------
  // HR: everyone scanned on one day
  // ---------------------------------------------------------------------

  static Future<Uint8List> buildScannedTodayReport(
    List<ScannedEntry> entries,
    DateTime date,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _reportHeader(
          'Attendance scanned',
          DateFormat('EEEE, MMMM d, y').format(date),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _table(
            const ['Employee', 'Department', 'Position', 'Time'],
            entries
                .map((e) => [
                      e.employeeName,
                      e.department,
                      e.position,
                      DateFormat.jm().format(e.scannedAt),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Total scanned: ${entries.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ---------------------------------------------------------------------
  // HR: present/absent summary for a date range
  // ---------------------------------------------------------------------

  static Future<Uint8List> buildAttendanceReport({
    required List<ReportRow> rows,
    required String periodLabel,
    required String rangeLabel,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _reportHeader('$periodLabel attendance report', rangeLabel),
        build: (context) => [
          pw.SizedBox(height: 12),
          _table(
            const ['Employee', 'Department', 'Present', 'Absent', 'Rate'],
            rows
                .map((r) => [
                      r.employeeName,
                      r.department,
                      '${r.presentDays}',
                      '${r.absentDays}',
                      r.rate == null ? '—' : '${(r.rate! * 100).round()}%',
                    ])
                .toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ---------------------------------------------------------------------
  // Shared report building blocks
  // ---------------------------------------------------------------------

  static pw.Widget _reportHeader(String title, String subtitle) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
          pw.SizedBox(height: 2),
          pw.Text(subtitle,
              style: const pw.TextStyle(fontSize: 10, color: _muted)),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
        ],
      );

  /// Plain, dependency-light table: a header row plus one row per record.
  static pw.Widget _table(List<String> headers, List<List<String>> data) {
    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _ink),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        for (final row in data)
          pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 5),
                    child:
                        pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
