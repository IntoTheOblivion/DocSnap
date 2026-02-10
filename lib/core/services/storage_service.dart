import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/shared_prefs_provider.dart';

part 'storage_service.g.dart';

@immutable
class StorageState {
  final String? rootPath;
  final int sortOption;

  const StorageState({this.rootPath, this.sortOption = 0});

  StorageState copyWith({String? rootPath, int? sortOption}) {
    return StorageState(
      rootPath: rootPath ?? this.rootPath,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

@Riverpod(keepAlive: true)
class StorageService extends _$StorageService {
  static const _keyRootPath = 'root_folder_path';
  static const _keySortOption = 'sort_option';

  @override
  StorageState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return StorageState(
      rootPath: prefs.getString(_keyRootPath),
      sortOption: prefs.getInt(_keySortOption) ?? 0,
    );
  }

  Future<void> setRootPath(String path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyRootPath, path);
    state = state.copyWith(rootPath: path);
  }

  Future<void> clearRootPath() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_keyRootPath);
    // Directly instantiate to allow nullifying rootPath
    state = StorageState(rootPath: null, sortOption: state.sortOption);
  }

  Future<void> setSortOption(int option) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_keySortOption, option);
    state = state.copyWith(sortOption: option);
  }
}
