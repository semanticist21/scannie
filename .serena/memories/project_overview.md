# Scannie - Document Scanner Flutter App

## Project Purpose
Mobile document scanning application (iOS/Android) with native camera integration, CamScanner-style filters, and PDF export capabilities.

## Tech Stack
- **Framework**: Flutter 3.39.0-0.1.pre (beta channel), Dart 3.11.0
- **UI**: Material Design 3
- **Document Scanning**: cunning_document_scanner_plus v1.0.3 (native iOS/Android scanner)
- **Image Processing**: image v4.5.4
- **Grid Management**: reorderable_grid_view v2.2.8
- **PDF Generation**: pdf v3.11.1, printing v5.13.4
- **Permissions**: permission_handler v12.0.1
- **File Management**: path_provider v2.0.11, path v1.8.2
- **UI Feedback**: fluttertoast v8.2.8

## Platform Support
- iOS: VNDocumentCameraViewController
- Android: Google ML Kit Document Scanner

## Current Status
✅ Document scanning with native filters/crop/rotation
✅ EditScreen image management (drag-drop reordering, deletion, addition)
✅ Session persistence (add images after scanning)
✅ PDF export with sharing

🚧 DocumentViewerScreen (not implemented)
🚧 ExportScreen (not implemented)
