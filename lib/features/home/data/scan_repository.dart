import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';

part 'scan_repository.g.dart';

@riverpod
ScanRepository scanRepository(Ref ref) {
  final storageState = ref.watch(storageServiceProvider);
  return ScanRepository(storageState);
}

@riverpod
class CurrentPath extends _$CurrentPath {
  @override
  String build() => '';

  void enterFolder(String folderName) {
    if (state.isEmpty) {
      state = folderName;
    } else {
      state = '$state/$folderName';
    }
  }

  void goBack() {
    if (state.isEmpty) return;
    final lastSeparator = state.lastIndexOf('/');
    if (lastSeparator == -1) {
      state = '';
    } else {
      state = state.substring(0, lastSeparator);
    }
  }
}

@riverpod
Future<List<FileSystemEntity>> scansList(Ref ref) async {
  final repository = ref.watch(scanRepositoryProvider);
  final currentPath = ref.watch(currentPathProvider);
  // repository is rebuilt when storage changes, so this will re-execute automatically
  return repository.getScans(currentPath);
}

class ScanRepository {
  final StorageState _storage;

  ScanRepository(this._storage);

  Future<Directory> _getRootDirectory() async {
    final customPath = _storage.rootPath;
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return dir;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<List<FileSystemEntity>> getScans(String relativePath) async {
    final rootDir = await _getRootDirectory();
    final dir = relativePath.isEmpty 
        ? rootDir 
        : Directory('${rootDir.path}/$relativePath');
    
    if (!await dir.exists()) {
      return [];
    }

    // Try/Catch for permission issues
    try {
      final entities = dir.listSync().where((entity) {
        final isPdf = entity is File && entity.path.endsWith('.pdf');
        final isDir = entity is Directory;
        return isPdf || isDir;
      }).toList();
      
      final sortOption = _storage.sortOption;

      // Sort
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;

        // 0: Date Desc (Newest first)
        // 1: Date Asc (Oldest first)
        // 2: Name Asc (A-Z)
        // 3: Name Desc (Z-A)
        
        switch (sortOption) {
          case 0: // Date Desc
             return b.statSync().modified.compareTo(a.statSync().modified);
          case 1: // Date Asc
             return a.statSync().modified.compareTo(b.statSync().modified);
          case 2: // Name Asc
             return a.uri.pathSegments.last.toLowerCase().compareTo(b.uri.pathSegments.last.toLowerCase());
          case 3: // Name Desc
             return b.uri.pathSegments.last.toLowerCase().compareTo(a.uri.pathSegments.last.toLowerCase());
          default:
             return b.statSync().modified.compareTo(a.statSync().modified);
        }
      });
      
      return entities;
    } catch (e) {
      // Permission denied or other error
      return [];
    }
  }

  Future<void> createFolder(String relativePath, String folderName) async {
    final rootDir = await _getRootDirectory();
    final parentPath = relativePath.isEmpty 
        ? rootDir.path 
        : '${rootDir.path}/$relativePath';
    
    final newDir = Directory('$parentPath/$folderName');
    if (!await newDir.exists()) {
      await newDir.create();
    }
  }

  Future<void> renameFolder(String path, String newName) async {
     try {
       final dir = Directory(path);
       if (await dir.exists()) {
         final parentPath = dir.parent.path;
         final sanitized = newName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
         final newPath = '$parentPath/$sanitized';
         
         if (dir.path == newPath) return;
         await dir.rename(newPath);
       }
     } catch (e) {
       throw Exception('Failed to rename folder: $e');
     }
  }

  Future<void> deleteFolder(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> deleteScan(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  Future<void> renameScan(String path, String newName) async {
     try {
       final file = File(path);
       if (await file.exists()) {
         final parentPath = file.parent.path;
         final sanitized = newName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
         final newPath = '$parentPath/$sanitized.pdf';
         
         if (file.path == newPath) return;

         await file.rename(newPath);
       }
     } catch (e) {
       throw Exception('Failed to rename: $e');
     }
  }
}
