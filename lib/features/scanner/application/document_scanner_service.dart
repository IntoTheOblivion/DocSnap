import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'document_scanner_service.g.dart';

@riverpod
DocumentScannerService documentScannerService(Ref ref) {
  return DocumentScannerService();
}

class DocumentScannerService {
  final _documentScanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 100,
      isGalleryImport: true, // Set to true to allow importing from gallery
    ),
  );

  /// Opens the ML Kit Document Scanner.
  /// Returns a list of file paths to the scanned JPEG images.
  Future<List<String>> scanDocument() async {
    try {
      final result = await _documentScanner.scanDocument();
      
      // images are saved in the temp directory by the plugin
      return result.images;
    } on PlatformException catch (e) {
      // Handle the case where the user cancels
      if (e.code == 'ScannerCancelled') {
        return [];
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _documentScanner.close();
  }
}
