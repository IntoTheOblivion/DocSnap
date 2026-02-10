// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scanRepositoryHash() => r'03f01ab83454a26da10130323288a8479079b069';

/// See also [scanRepository].
@ProviderFor(scanRepository)
final scanRepositoryProvider = AutoDisposeProvider<ScanRepository>.internal(
  scanRepository,
  name: r'scanRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scanRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanRepositoryRef = AutoDisposeProviderRef<ScanRepository>;
String _$scansListHash() => r'9148452579b2065ce3ea628e43ae2282938d75a4';

/// See also [scansList].
@ProviderFor(scansList)
final scansListProvider =
    AutoDisposeFutureProvider<List<FileSystemEntity>>.internal(
  scansList,
  name: r'scansListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scansListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScansListRef = AutoDisposeFutureProviderRef<List<FileSystemEntity>>;
String _$currentPathHash() => r'cae63f5ed7c3e66ad783add2ee1957627f74e109';

/// See also [CurrentPath].
@ProviderFor(CurrentPath)
final currentPathProvider =
    AutoDisposeNotifierProvider<CurrentPath, String>.internal(
  CurrentPath.new,
  name: r'currentPathProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentPathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentPath = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
