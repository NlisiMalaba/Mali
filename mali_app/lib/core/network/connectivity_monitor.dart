import 'package:connectivity_plus/connectivity_plus.dart';

abstract final class ConnectivityMonitor {
  static bool isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  static Stream<bool> watchOnline(Connectivity connectivity) async* {
    yield isOnline(await connectivity.checkConnectivity());
    await for (final results in connectivity.onConnectivityChanged) {
      yield isOnline(results);
    }
  }
}
