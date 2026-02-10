import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/scan_repository.dart';
import 'home_controller.dart';
import '../../pdf_generator/presentation/edit_pdf_screen.dart';
import '../../../core/services/storage_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(scansListProvider);
    final currentPath = ref.watch(currentPathProvider);

    // Listen for errors to show SnackBar
    ref.listen<AsyncValue<List<FileSystemEntity>>>(scansListProvider,
        (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    return PopScope(
      canPop: currentPath.isEmpty,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(currentPathProvider.notifier).goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.document_scanner),
              ),
              const SizedBox(width: 8),
              if (currentPath.isEmpty)
                const Text(AppConstants.appName)
              else
                Expanded(
                    child: Text(currentPath.split('/').last,
                        overflow: TextOverflow.ellipsis)),
            ],
          ),
          leading: currentPath.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      ref.read(currentPathProvider.notifier).goBack(),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () => _showCreateFolderDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, ref),
            ),
          ],
        ),
        body: scansAsync.when(
          data: (scans) {
            if (scans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.document_scanner_outlined,
                          size: 64,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentPath.isEmpty
                          ? AppConstants.noScansMessage
                          : 'Empty Folder',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final entity = scans[index];
                if (entity is Directory) {
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: ListTile(
                      leading: const Icon(Icons.folder,
                          size: 40, color: Colors.amber),
                      title: Text(entity.uri.pathSegments
                          .where((e) => e.isNotEmpty)
                          .last),
                      onTap: () {
                        final folderName = entity.uri.pathSegments
                            .where((e) => e.isNotEmpty)
                            .last;
                        ref
                            .read(currentPathProvider.notifier)
                            .enterFolder(folderName);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Rename')
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete')
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'rename') {
                                _showRenameFolderDialog(
                                    context, ref, entity.path);
                              } else if (value == 'delete') {
                                _confirmDeleteFolder(context, ref, entity.path);
                              }
                            },
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                }

                final file = entity as File;
                final stat = file.statSync();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(file.uri.pathSegments.last),
                    subtitle: Text(DateFormatter.formatDateTime(stat.modified)),
                    onTap: () {
                      // Open the PDF
                      OpenFile.open(file.path);
                    },
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('Share')
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Rename')
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_pdf',
                          child: Row(
                            children: [
                              Icon(Icons.brush, size: 20),
                              SizedBox(width: 8),
                              Text('Edit / Sign')
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete')
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'share') {
                          Share.shareXFiles([XFile(file.path)]);
                        } else if (value == 'rename') {
                          _showRenameDialog(context, ref, file.path);
                        } else if (value == 'edit_pdf') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPdfScreen(file: file),
                            ),
                          ).then((_) {
                            // Refresh list when coming back, as a new file might have been saved
                            ref.invalidate(scansListProvider);
                          });
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, file.path);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ref.read(homeControllerProvider.notifier).startScan();
          },
          label: const Text('Scan'),
          icon: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text(AppConstants.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(homeControllerProvider.notifier).deleteScan(path);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String path) {
    final TextEditingController controller = TextEditingController(
      text: File(path).uri.pathSegments.last.replaceAll('.pdf', ''),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Scan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(homeControllerProvider.notifier)
                    .renameScan(path, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(homeControllerProvider.notifier).createFolder(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(
      BuildContext context, WidgetRef ref, String path) {
    final TextEditingController controller = TextEditingController(
      text: Directory(path).uri.pathSegments.where((e) => e.isNotEmpty).last,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(homeControllerProvider.notifier)
                    .renameFolder(path, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, WidgetRef ref, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: const Text(
            'Are you sure you want to delete this folder and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(homeControllerProvider.notifier).deleteFolder(path);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(storageServiceProvider);
    final currentRoot = storageState.rootPath;
    final currentSort = storageState.sortOption;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Storage Location',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                currentRoot ?? 'Default (App Documents)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog to pick file
                      if (Platform.isAndroid) {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Important'),
                            content: const Text(
                                'Due to Android 11+ security restrictions, you cannot select the root "Downloads" folder.\n\nPlease create a subfolder (e.g., "DocSnap") inside Downloads and select that instead.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref
                                      .read(homeControllerProvider.notifier)
                                      .pickRootFolder();
                                },
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        await ref
                            .read(homeControllerProvider.notifier)
                            .pickRootFolder();
                      }
                      // We can't re-open easily, relying on user to re-open settings or just see the change
                    },
                    child: const Text('Change Folder'),
                  ),
                  if (currentRoot != null)
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(homeControllerProvider.notifier)
                            .resetRootFolder();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const Divider(),
              const Text('Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: currentSort,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 0, child: Text('Date (Newest First)')),
                  DropdownMenuItem(
                      value: 1, child: Text('Date (Oldest First)')),
                  DropdownMenuItem(value: 2, child: Text('Name (A-Z)')),
                  DropdownMenuItem(value: 3, child: Text('Name (Z-A)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(homeControllerProvider.notifier)
                        .setSortOption(val);
                    setState(() {}); // Update local state for dropdown
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
