import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/scanned_document.dart';

class PdfService {
  /// 스캔한 이미지들을 PDF로 변환
  Future<String> createPdfFromImages(List<ScannedDocument> documents) async {
    final pdf = pw.Document();

    for (final doc in documents) {
      final imageFile = File(doc.imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    // PDF 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = '${directory.path}/$fileName';

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    return pdfPath;
  }

  /// PDF를 외부 저장소로 공유/저장
  Future<void> sharePdf(String pdfPath) async {
    // printing 패키지의 Printing.sharePdf() 사용 가능
    // 여기서는 기본 구조만 작성
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('PDF file not found');
    }
  }
}
