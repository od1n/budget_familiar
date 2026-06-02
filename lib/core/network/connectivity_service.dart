import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Stub temporal: connectivity_plus eliminado para evitar problemas de DLL
/// en Windows desktop. En Fase 2 (sync offline) se reincorpora el paquete
/// y esta implementación se reemplaza por la real.
@riverpod
Stream<bool> connectivity(ConnectivityRef ref) async* {
  yield true; // asume siempre conectado hasta implementar sync offline
}

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  bool build() {
    ref.listen(connectivityProvider, (_, next) {
      next.whenData((isConnected) => state = isConnected);
    });
    return true; // asume conectado por defecto
  }
}
