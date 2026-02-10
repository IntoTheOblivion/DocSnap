import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:file_picker/file_picker.dart';
import '../../scanner/application/document_scanner_service.dart';
import '../../pdf_generator/application/pdf_generator_service.dart';
import '../data/scan_repository.dart';
import '../../../core/services/storage_service.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  FutureOr<void> build() {
    // nothing to initialize
  }

  Future<void> startScan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final scanner = ref.read(documentScannerServiceProvider);
      final pdfGenerator = ref.read(pdfGeneratorServiceProvider);
      
      // 1. Scan Documents
      final images = await scanner.scanDocument();
      
      if (images.isNotEmpty) {
        // 2. Generate PDF
        await pdfGenerator.createPdfFromImages(images);
        
        // 3. Refresh the list
        ref.invalidate(scansListProvider);
      }
    });
  }

  Future<void> renameScan(String path, String newName) async {
    try {
      final repository = ref.read(scanRepositoryProvider);
      await repository.renameScan(path, newName);
      ref.invalidate(scansListProvider);
    } catch (e) {
      // For now, we swallow the error to prevent crash, 
      // ideally we'd show a valid Snackbar in the UI
      debugPrint('Rename failed: $e');
    }
  }

  Future<void> createFolder(String folderName) async {
    final repository = ref.read(scanRepositoryProvider);
    final currentPath = ref.read(currentPathProvider);
    await repository.createFolder(currentPath, folderName);
    ref.invalidate(scansListProvider);
  }

  Future<void> renameFolder(String path, String newName) async {
    final repository = ref.read(scanRepositoryProvider); // Use read for actions
    await repository.renameFolder(path, newName);
    ref.invalidate(scansListProvider);
  }

  Future<void> deleteFolder(String path) async {
    final repository = ref.read(scanRepositoryProvider);
    await repository.deleteFolder(path);
    ref.invalidate(scansListProvider);
  }

  Future<void> deleteScan(String path) async {
    final repository = ref.read(scanRepositoryProvider);
    await repository.deleteScan(path);
    ref.invalidate(scansListProvider);
  }

  Future<void> pickRootFolder() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final storage = ref.read(storageServiceProvider.notifier);
        await storage.setRootPath(selectedDirectory);
        // ScansList updates automatically via ScanRepository watch
        ref.invalidate(currentPathProvider); // Reset current path to root
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
    }
  }

  Future<void> setSortOption(int option) async {
    final storage = ref.read(storageServiceProvider.notifier);
    await storage.setSortOption(option);
  }

  Future<void> resetRootFolder() async {
    final storage = ref.read(storageServiceProvider.notifier);
    await storage.clearRootPath();
    ref.invalidate(currentPathProvider);
  }
}
