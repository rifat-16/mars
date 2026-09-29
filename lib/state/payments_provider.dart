import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/state/async_state.dart';
import '../data/repositories/payments_repository.dart';
import '../models/domain/payment.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentsRepository _paymentsRepository;

  PaymentsProvider(this._paymentsRepository);

  AsyncState<List<Payment>> _state = const AsyncState.idle();
  StreamSubscription<List<Payment>>? _subscription;

  AsyncState<List<Payment>> get state => _state;

  Future<void> listenPayments() async {
    await _subscription?.cancel();
    _state = const AsyncState.loading();
    notifyListeners();

    _subscription = _paymentsRepository.watchPayments().listen(
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
