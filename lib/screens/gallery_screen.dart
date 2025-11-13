import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models/scanned_document.dart';
import '../services/pdf_service.dart';
import '../providers/document_provider.dart';
import 'edit_screen.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  Future<void> _createPdf(BuildContext context, DocumentProvider provider) async {
    if (provider.documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스캔된 문서가 없습니다')),
      );
      return;
    }

    if (!provider.canCreatePdf()) {
      _showPdfLimitDialog(context, provider);
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfService = PdfService();
      final pdfPath = await pdfService.createPdfFromImages(provider.documents);

      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기

        // PDF 생성 횟수 증가
        provider.incrementPdfCount();

        // 공유 또는 저장 옵션 표시
        _showPdfOptionsDialog(context, pdfPath);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 생성 실패: $e')),
        );
      }
    }
  }

  void _showPdfLimitDialog(BuildContext context, DocumentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('무료 사용 제한'),
        content: Text(
          '오늘 무료 PDF 생성 횟수를 모두 사용했습니다.\n'
          '(${provider.pdfCreatedToday}/${provider.maxPdfPerDay})\n\n'
          '프리미엄으로 업그레이드하여 무제한으로 사용하세요!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 프리미엄 구독 페이지로 이동
              Navigator.pop(context);
            },
            child: const Text('프리미엄 보기'),
          ),
        ],
      ),
    );
  }

  void _showPdfOptionsDialog(BuildContext context, String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 생성 완료'),
        content: const Text('PDF를 저장하거나 공유할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 파일 다운로드
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF 저장 위치: $pdfPath')),
              );
            },
            child: const Text('다운로드'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // PDF 공유
              try {
                final file = File(pdfPath);
                final bytes = await file.readAsBytes();
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('공유 실패: $e')),
                  );
                }
              }
            },
            child: const Text('공유하기'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(BuildContext context, DocumentProvider provider, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 문서를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeDocument(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('문서가 삭제되었습니다')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('보관함'),
            actions: [
              // PDF 생성 버튼
              IconButton(
                onPressed: () => _createPdf(context, provider),
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'PDF로 변환 (${provider.pdfCreatedToday}/${provider.maxPdfPerDay})',
              ),
            ],
          ),
          body: provider.documents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.scanner, size: 100, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '스캔된 문서가 없습니다',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '하단의 "스캔하기" 버튼을 눌러\n문서를 스캔해보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.documents.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderDocuments(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final doc = provider.documents[index];
                    return Card(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(doc.imagePath),
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        title: Text('문서 ${index + 1}'),
                        subtitle: Text(
                          '${doc.createdAt.year}-${doc.createdAt.month.toString().padLeft(2, '0')}-${doc.createdAt.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push<ScannedDocument>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditScreen(document: doc),
                                  ),
                                );
                                if (result != null) {
                                  provider.updateDocument(index, result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDocument(context, provider, index),
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
