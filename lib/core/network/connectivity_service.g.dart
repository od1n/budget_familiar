// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityHash() => r'7507985a5b5b464cde55819de6b07cb07d9fdfd7';

/// Stub temporal: connectivity_plus eliminado para evitar problemas de DLL
/// en Windows desktop. En Fase 2 (sync offline) se reincorpora el paquete
/// y esta implementación se reemplaza por la real.
///
/// Copied from [connectivity].
@ProviderFor(connectivity)
final connectivityProvider = AutoDisposeStreamProvider<bool>.internal(
  connectivity,
  name: r'connectivityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$connectivityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConnectivityRef = AutoDisposeStreamProviderRef<bool>;
String _$connectivityNotifierHash() =>
    r'23c747bd6749a86194bf3018898c82e60422ad7f';

/// See also [ConnectivityNotifier].
@ProviderFor(ConnectivityNotifier)
final connectivityNotifierProvider =
    AutoDisposeNotifierProvider<ConnectivityNotifier, bool>.internal(
  ConnectivityNotifier.new,
  name: r'connectivityNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectivityNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
