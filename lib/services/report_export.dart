import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Hasil tangkapan laporan sebagai gambar PNG.
class ReportImage {
  const ReportImage(this.png, this.width, this.height);
  final Uint8List png;
  final int width, height;
}

/// Batas tinggi gambar (px): di atas ini tekstur GPU bisa gagal dibuat.
const _maxPixels = 8000.0;

/// Tangkap isi [boundary] (seluruh tinggi isinya, termasuk yang di luar
/// layar) sebagai PNG tajam; resolusi diturunkan otomatis bila terlalu tinggi.
Future<ReportImage> captureReport(
  GlobalKey boundary, {
  double pixelRatio = 3,
}) async {
  final object = boundary.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) {
    throw StateError('Laporan belum siap ditangkap');
  }
  // tunggu frame yang sedang digambar selesai
  if (kDebugMode && object.debugNeedsPaint) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  final ratio = math.max(
    1.0,
    math.min(pixelRatio, _maxPixels / object.size.height),
  );
  final image = await object.toImage(pixelRatio: ratio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('Gagal membuat gambar');
  return ReportImage(data.buffer.asUint8List(), image.width, image.height);
}

/// Bungkus gambar laporan jadi satu halaman PDF selebar A4 (tinggi mengikuti
/// isi, jadi tidak ada yang terpotong).
Future<Uint8List> reportToPdf(ReportImage image, {String? title}) async {
  const width = 595.28; // lebar A4, pt
  var pageWidth = width;
  var pageHeight = width * image.height / image.width;
  // batas ukuran halaman PDF ±14400 pt
  if (pageHeight > 14000) {
    pageWidth = width * 14000 / pageHeight;
    pageHeight = 14000;
  }
  final doc = pw.Document(title: title, creator: 'Bilal+');
  final picture = pw.MemoryImage(image.png);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(pageWidth, pageHeight),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(picture, fit: pw.BoxFit.fill),
    ),
  );
  return doc.save();
}

/// Buka lembar bagikan sistem: dari sana pengguna bisa menyimpan ke berkas/
/// unduhan, Drive, atau mengirimnya lewat aplikasi lain.
Future<ShareResult> shareReport(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [fileName],
      subject: subject,
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
