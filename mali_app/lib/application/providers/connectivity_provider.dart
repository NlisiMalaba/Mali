import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mali_app/core/network/connectivity_monitor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
Connectivity connectivityClient(Ref ref) {
  return Connectivity();
}

@Riverpod(keepAlive: true)
Stream<bool> connectivity(Ref ref) {
  return ConnectivityMonitor.watchOnline(ref.watch(connectivityClientProvider));
}
