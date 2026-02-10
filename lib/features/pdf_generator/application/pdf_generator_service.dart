import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:pdf/pdf.dart';
import 'package:image/image.dart' as img; // Re-added for fallback decoding
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Native compression
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/storage_service.dart';

part 'pdf_generator_service.g.dart';

@riverpod
PdfGeneratorService pdfGeneratorService(Ref ref) {
  final storage = ref.watch(storageServiceProvider);
  return PdfGeneratorService(storage);
}

class PdfGeneratorService {
  final StorageState _storage;

  PdfGeneratorService(this._storage);

  /// Converts a list of image files into a single multi-page PDF.
  /// Saves the PDF to the configured storage directory.
  Future<File> createPdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      File file = File(path);

      // AGGRESSIVE COMPRESSION: Resize to temp file natively if needed
      // This prevents reading 10MB+ files into RAM.
      try {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            '${tempDir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}.jpg';

        // Compress and resize to max 1920x1080 (or similar safe size)
        // quality 85 is usually good enough for docs
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          path,
          targetPath,
          minWidth: 1920,
          minHeight: 1920,
          quality: 85,
        );

        if (compressedFile != null) {
          file = File(compressedFile.path);
        }
      } catch (e) {
        debugPrint('Compression failed, using original file: $e');
      }

      final bytes = file.readAsBytesSync();

      // Create PdfImage from bytes directly (avoids decoding to RGBA in Dart)
      // This supports Jpeg, Png, etc. efficiently.
      // Try to add image directly (fastest, keeps quality)
      try {
        final pdfDocImage = PdfImage.file(
          pdf.document,
          bytes: bytes,
        );

        final pageFormat = PdfPageFormat(
            pdfDocImage.width.toDouble(), pdfDocImage.height.toDouble());

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pw.ImageProxy(pdfDocImage),
                    fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      } catch (e) {
        // Fallback: If direct embedding fails (e.g. format issue or memory),
        // decode and resize the image to a safe resolution.
        debugPrint('Direct PDF embed failed, falling back to resize: $e');

        try {
          // Decode the image
          var decodedImg = img.decodeImage(bytes);

          if (decodedImg != null) {
            // Resize if it's too large (e.g. > 2000px) to save memory
            if (decodedImg.width > 2000 || decodedImg.height > 2000) {
              decodedImg = img.copyResize(
                decodedImg,
                width: decodedImg.width > decodedImg.height ? 2000 : null,
                height: decodedImg.height > decodedImg.width ? 2000 : null,
              );
            }

            // Re-encode to JPG for PDF
            final reducedBytes = img.encodeJpg(decodedImg, quality: 85);
            final image = pw.MemoryImage(reducedBytes);

            final pageFormat = PdfPageFormat(
                decodedImg.width.toDouble(), decodedImg.height.toDouble());

            pdf.addPage(
              pw.Page(
                pageFormat: pageFormat,
                margin: pw.EdgeInsets.zero,
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  );
                },
              ),
            );
          }
        } catch (e2) {
          debugPrint('Fatal error adding image to PDF: $e2');
          // Skip this image or show error
        }
      }
    }

    Directory outputDir;
    final customPath = _storage.rootPath;
    if (customPath != null && customPath.isNotEmpty) {
      outputDir = Directory(customPath);
      if (!await outputDir.exists()) {
        // Fallback or create? Better to fallback if invalid, but maybe user wants it created.
        // For now, if it doesn't exist, we might try to create it or fallback.
        // Let's fallback to safely avoid crashes.
        if (!await outputDir.exists()) {
          outputDir = await getApplicationDocumentsDirectory();
        }
      }
    } else {
      outputDir = await getApplicationDocumentsDirectory();
    }

    final fileName =
        'Scan_${DateFormatter.formatForFilename(DateTime.now())}.pdf';
    final file = File('${outputDir.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
