import 'package:mali_app/core/security/pin_lock_store.dart';
import 'package:mali_app/data/repositories/secure_pin_lock_repository.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pin_lock_store_providers.g.dart';

@Riverpod(keepAlive: true)
IPinLockStore pinLockStore(Ref ref) {
  return const SecurePinLockStore();
}

@Riverpod(keepAlive: true)
IPinLockRepository pinLockRepository(Ref ref) {
  return SecurePinLockRepository(
    pinLockStore: ref.watch(pinLockStoreProvider),
  );
}
