import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/state/async_state.dart';
import '../data/repositories/inventory_repository.dart';
import '../models/domain/inventory_item.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _inventoryRepository;

  InventoryProvider(this._inventoryRepository);

  AsyncState<List<InventoryItem>> _state = const AsyncState.idle();
  StreamSubscription<List<InventoryItem>>? _subscription;

  AsyncState<List<InventoryItem>> get state => _state;

  Future<void> listenInventory() async {
    await _subscription?.cancel();
    _state = const AsyncState.loading();
    notifyListeners();

    _subscription = _inventoryRepository.watchInventory().listen(
      (items) {
        _state = AsyncState.success(items);
        notifyListeners();
      },
      onError: (Object error) {
        _state = AsyncState.error(error.toString());
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
