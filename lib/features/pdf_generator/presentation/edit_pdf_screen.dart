import 'dart:io';
import 'dart:math';
import 'dart:ui'; // For ImageFilter
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/services/storage_service.dart';

class EditPdfScreen extends ConsumerStatefulWidget {
  final File file;
  const EditPdfScreen({super.key, required this.file});

  @override
  ConsumerState<EditPdfScreen> createState() => _EditPdfScreenState();
}

class PageModel {
  final File file;
  final double aspectRatio;
  final int width;
  final int height;

  PageModel({
    required this.file,
    required this.aspectRatio,
    required this.width,
    required this.height,
  });
}

class _EditPdfScreenState extends ConsumerState<EditPdfScreen> {
  List<PageModel> _pages = [];
  bool _isLoading = true;
  int _currentPage = 0;

  // Map pageIndex -> List of Overlays
  final Map<int, List<OverlayItem>> _overlays = {};

  OverlayItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  @override
  void dispose() {
    for (final page in _pages) {
      if (page.file.existsSync()) {
        try {
          page.file.deleteSync();
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }
    }
    super.dispose();
  }

  Future<void> _loadPages() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use standard raster dpi. 100 is enough for screen and saves memory.
      int index = 0;
      await for (final page in Printing.raster(bytes, dpi: 100)) {
        final png = await page.toPng();
        final file = File('${tempDir.path}/page_${timestamp}_$index.png');
        await file.writeAsBytes(png);

        // Use dimensions from raster directly
        _pages.add(PageModel(
          file: file,
          aspectRatio: page.width / page.height,
          width: page.width,
          height: page.height,
        ));
        index++;
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTextOverlay(
      {String text = '', Offset? position, Size? size}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextEditDialog(initialText: text),
    );

    if (result != null && result.isNotEmpty) {
      _addOverlay(OverlayItem(
        type: OverlayType.text,
        text: result,
        position: position ?? const Offset(0.5, 0.5),
        size: size ?? const Size(150, 50),
      ));
    }
  }

  Future<void> _editOverlay(OverlayItem item) async {
    if (item.type != OverlayType.text) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextEditDialog(initialText: item.text ?? ''),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        item.text = result;
      });
    }
  }

  void _addSignatureOverlay() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sign Here',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Container(
              height: 200,
              width: double.maxFinite,
              color: Colors.grey[100],
              child: Signature(
                controller: controller,
                backgroundColor: Colors.transparent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => controller.clear(),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (controller.isNotEmpty) {
                        final bytes = await controller.toPngBytes();
                        if (bytes != null) {
                          // Calculate aspect ratio
                          final img = await decodeImageFromList(bytes);
                          final aspectRatio = img.width / img.height;
                          final width = 150.0;
                          final height = width / aspectRatio;

                          _addOverlay(OverlayItem(
                            type: OverlayType.signature,
                            signatureBytes: bytes,
                            position: const Offset(0.5, 0.5),
                            size: Size(width, height),
                          ));
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Signature'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _addOverlay(OverlayItem item) {
    setState(() {
      if (_overlays[_currentPage] == null) {
        _overlays[_currentPage] = [];
      }
      _overlays[_currentPage]!.add(item);
      _selectedItem = item; // Auto-select new item
    });
  }

  void _deleteSelected() {
    if (_selectedItem != null && _overlays[_currentPage] != null) {
      setState(() {
        _overlays[_currentPage]!.remove(_selectedItem);
        _selectedItem = null;
      });
    }
  }

  // Smart Insert Logic
  void _handleTap(
      TapUpDetails details, BoxConstraints constraints, double aspectRatio) {
    // If we have an item selected, deselect it
    if (_selectedItem != null) {
      setState(() => _selectedItem = null);
      return;
    }
  }

  // Note: _detectAndInsert was removed due to complexity issues.

  Future<void> _savePdf() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      for (int i = 0; i < _pages.length; i++) {
        final pageModel = _pages[i];
        final imageBytes = await pageModel.file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        final pageOverlays = _overlays[i] ?? [];

        // Use cached dimensions
        final pdfPageFormat = PdfPageFormat(
            pageModel.width * 72.0 / 100.0, pageModel.height * 72.0 / 100.0);

        pdf.addPage(
          pw.Page(
            pageFormat: pdfPageFormat,
            margin: pw.EdgeInsets.zero, // Remove default margins
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
                  ...pageOverlays.map((overlay) {
                    final x = overlay.position.dx * pdfPageFormat.width;
                    final y = overlay.position.dy * pdfPageFormat.height;

                    if (overlay.type == OverlayType.text) {
                      return pw.Positioned(
                        left: x - (overlay.size.width / 2),
                        top: y - (overlay.size.height / 2),
                        child: pw.SizedBox(
                          width: overlay.size.width,
                          height: overlay.size.height,
                          // Use FittedBox to auto-scale text in PDF
                          child: pw.FittedBox(
                            fit: pw.BoxFit.contain,
                            child: pw.Text(
                              overlay.text ?? '',
                              style: pw.TextStyle(
                                  fontSize: 40,
                                  color: PdfColors
                                      .black), // Large default size, scaled down
                            ),
                          ),
                        ),
                      );
                    } else {
                      return pw.Positioned(
                        left: x - (overlay.size.width / 2),
                        top: y - (overlay.size.height / 2),
                        child: pw.Image(
                          pw.MemoryImage(overlay.signatureBytes!),
                          width: overlay.size.width,
                          height: overlay.size.height,
                          fit: pw.BoxFit.fill,
                        ),
                      );
                    }
                  }),
                ],
              );
            },
          ),
        );
      }

      Directory outputDir;
      final storageState = ref.read(storageServiceProvider);
      final customPath = storageState.rootPath;

      if (customPath != null && customPath.isNotEmpty) {
        outputDir = Directory(customPath);
        if (!await outputDir.exists()) {
          outputDir = await getApplicationDocumentsDirectory();
        }
      } else {
        outputDir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'Edited_${DateFormatter.formatForFilename(DateTime.now())}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF Saved!')));
        Navigator.pop(context); // Go back to home to see new file
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background for contrast
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _savePdf,
            child: const Text('Done',
                style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // PDF Content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() {
                    _currentPage = index;
                    _selectedItem = null;
                  }),
                  itemBuilder: (context, index) {
                    final pageModel = _pages[index];
                    // No FutureBuilder needed!
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapUp: (details) => _handleTap(
                              details, constraints, pageModel.aspectRatio),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: pageModel.aspectRatio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      pageModel.file,
                                      fit:
                                          BoxFit.contain, // Matches AspectRatio
                                    ),
                                    // Overlays
                                    ...(_overlays[index] ?? []).map((overlay) {
                                      return _ResizableWidget(
                                        item: overlay,
                                        isSelected: overlay == _selectedItem,
                                        parentSize: Size(
                                            constraints.maxWidth,
                                            constraints.maxWidth /
                                                pageModel
                                                    .aspectRatio), // Approx size, but widget uses relative
                                        onTap: () => setState(
                                            () => _selectedItem = overlay),
                                        onChanged: (pos, size) {
                                          setState(() {
                                            overlay.position = pos;
                                            overlay.size = size;
                                          });
                                        },
                                        onDoubleTap: () =>
                                            _editOverlay(overlay),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating Toolbar
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: _buildToolbarContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Toolbar Content based on selection
  Widget _buildToolbarContent() {
    if (_selectedItem != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
              icon: Icons.close,
              label: 'Deselect',
              onTap: () => setState(() => _selectedItem = null)),
          Container(
              height: 20,
              width: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          if (_selectedItem!.type == OverlayType.text)
            _ToolbarButton(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () => _editOverlay(_selectedItem!)),
          _ToolbarButton(
              icon: Icons.delete,
              label: 'Delete',
              color: Colors.redAccent,
              onTap: _deleteSelected),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: _addTextOverlay,
            isPrimary: true,
          ),
          const SizedBox(width: 20),
          _ToolbarButton(
            icon: Icons.draw,
            label: 'Sign',
            onTap: _addSignatureOverlay,
            isPrimary: true,
          ),
        ],
      );
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isPrimary;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.blueAccent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ResizableWidget extends StatefulWidget {
  final OverlayItem item;
  final bool isSelected;
  final Size parentSize;
  final VoidCallback onTap;
  final Function(Offset, Size) onChanged;
  final VoidCallback onDoubleTap;

  const _ResizableWidget({
    required this.item,
    required this.isSelected,
    required this.parentSize,
    required this.onTap,
    required this.onChanged,
    required this.onDoubleTap,
  });

  @override
  State<_ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<_ResizableWidget> {
  Offset? _startDragPos;
  Offset? _startItemPos;
  Size? _startItemSize;
  double? _startAspectRatio;

  @override
  Widget build(BuildContext context) {
    final left = widget.item.position.dx * widget.parentSize.width -
        (widget.item.size.width / 2);
    final top = widget.item.position.dy * widget.parentSize.height -
        (widget.item.size.height / 2);

    return Positioned(
      left: left,
      top: top,
      width: widget.item.size.width +
          (widget.isSelected ? 40 : 0), // buffer for handles
      height: widget.item.size.height + (widget.isSelected ? 40 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content
          Positioned(
            top: widget.isSelected ? 20 : 0,
            left: widget.isSelected ? 20 : 0,
            width: widget.item.size.width,
            height: widget.item.size.height,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanStart: (details) {
                _startDragPos = details.globalPosition;
                _startItemPos = widget.item.position;
                widget.onTap();
              },
              onPanUpdate: (details) {
                if (_startDragPos == null || _startItemPos == null) return;

                final delta = details.globalPosition - _startDragPos!;
                final dx = delta.dx / widget.parentSize.width;
                final dy = delta.dy / widget.parentSize.height;

                widget.onChanged(
                  Offset(_startItemPos!.dx + dx, _startItemPos!.dy + dy),
                  widget.item.size,
                );
              },
              onDoubleTap: widget.onDoubleTap,
              child: Container(
                decoration: widget.isSelected
                    ? BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2),
                        color: Colors.blueAccent.withOpacity(0.1),
                      )
                    : null,
                child: widget.item.type == OverlayType.text
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.item.text ?? '',
                            style: const TextStyle(
                                fontSize: 40, color: Colors.black),
                          ),
                        ),
                      )
                    : Image.memory(
                        widget.item.signatureBytes!,
                        fit: BoxFit.fill,
                      ),
              ),
            ),
          ),

          // Resize Handle (Bottom Right)
          if (widget.isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  _startDragPos = details.globalPosition;
                  _startItemSize = widget.item.size;
                  _startAspectRatio =
                      widget.item.size.width / widget.item.size.height;
                },
                onPanUpdate: (details) {
                  if (_startDragPos == null ||
                      _startItemSize == null ||
                      _startAspectRatio == null) return;
                  final delta = details.globalPosition - _startDragPos!;

                  // Aspect Ratio Locked Resize
                  // We calculate based on Width change
                  double newWidth = max(50.0, _startItemSize!.width + delta.dx);

                  // Derive Height from valid Width to preserve Ratio
                  double newHeight = newWidth / _startAspectRatio!;

                  widget.onChanged(
                      widget.item.position, Size(newWidth, newHeight));
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.crop_free,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum OverlayType { text, signature }

class OverlayItem {
  Offset position; // Normalized (0-1) center position
  Size size; // Logical pixels on screen
  final OverlayType type;
  String? text;
  final Uint8List? signatureBytes;

  OverlayItem({
    required this.position,
    required this.type,
    required this.size,
    this.text,
    this.signatureBytes,
  });
}

class _TextEditDialog extends StatefulWidget {
  final String initialText;
  const _TextEditDialog({this.initialText = ''});

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialText.isEmpty ? 'Add Text' : 'Edit Text'),
      content: TextField(
        controller: _controller,
        autofocus: false,
        decoration: const InputDecoration(
          hintText: 'Enter text here',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
