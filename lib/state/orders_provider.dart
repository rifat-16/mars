import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/state/async_state.dart';
import '../data/repositories/orders_repository.dart';
import '../models/domain/event_assignment_option.dart';
import '../models/domain/order.dart';
import '../models/domain/order_item.dart';

class OrdersProvider extends ChangeNotifier {
  final OrdersRepository _ordersRepository;

  OrdersProvider(this._ordersRepository);

  AsyncState<List<Order>> _ordersState = const AsyncState.idle();
  AsyncState<void> _actionState = const AsyncState.idle();
  Map<String, double> _medicinePrices = {};
  List<Map<String, String>> _previousCustomers = [];
  List<EventAssignmentOption> _eventAssignmentOptions = [];
  StreamSubscription<List<Order>>? _ordersSubscription;

  AsyncState<List<Order>> get ordersState => _ordersState;
  AsyncState<void> get actionState => _actionState;
  Map<String, double> get medicinePrices => _medicinePrices;
  List<Map<String, String>> get previousCustomers => _previousCustomers;
  List<EventAssignmentOption> get eventAssignmentOptions =>
      _eventAssignmentOptions;

  Stream<Order?> watchOrderById(String orderId) {
    return _ordersRepository.watchOrderById(orderId);
  }

  Future<void> listenOrders({
    required String role,
    required String userPhone,
  }) async {
    await _ordersSubscription?.cancel();
    _ordersState = const AsyncState.loading();
    notifyListeners();

    _ordersSubscription = _ordersRepository
        .watchOrders(role: role, userPhone: userPhone)
        .listen(
          (orders) {
            _ordersState = AsyncState.success(orders);
            notifyListeners();
          },
          onError: (Object error) {
            _ordersState = AsyncState.error(error.toString());
            notifyListeners();
          },
        );
  }

  Future<void> loadCreateOrderDependencies({
    required String role,
    required String currentUid,
  }) async {
    _actionState = const AsyncState.loading();
    notifyListeners();

    try {
      final products = await _ordersRepository.fetchMedicinePrices();
      final customers = await _ordersRepository.fetchPreviousCustomers();
      final eventOptions = await _ordersRepository.fetchEventAssignmentOptions(
        role: role,
        currentUid: currentUid,
      );
      _medicinePrices = products;
      _previousCustomers = customers;
      _eventAssignmentOptions = eventOptions;
      _actionState = const AsyncState.success(null);
    } catch (e) {
      _actionState = AsyncState.error('Failed to load order dependencies: $e');
    }

    notifyListeners();
  }

  Future<bool> createOrder({
    required String customerName,
    required String address,
    required String phoneNumber,
    required List<OrderItem> items,
    String? eventId,
    String? eventRegistrationId,
    String? eventParticipantUid,
  }) async {
    _actionState = const AsyncState.loading();
    notifyListeners();

    try {
      var total = 0.0;
      for (final item in items) {
        final unitPrice = _medicinePrices[item.product] ?? 0;
        total += unitPrice * item.quantity;
      }

      await _ordersRepository.createOrder(
        customerName: customerName,
        address: address,
        phoneNumber: phoneNumber,
        items: items,
        totalAmount: total,
        eventId: eventId,
        eventRegistrationId: eventRegistrationId,
        eventParticipantUid: eventParticipantUid,
      );

      _actionState = const AsyncState.success(null);
      notifyListeners();
      return true;
    } catch (e) {
      _actionState = AsyncState.error('Failed to create order: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markOrderDelivered({
    required String orderId,
    required List<OrderItem> items,
    required String actorUid,
    required String actorName,
  }) async {
    _actionState = const AsyncState.loading();
    notifyListeners();

    try {
      await _ordersRepository.markOrderDelivered(
        orderId: orderId,
        items: items,
        actorUid: actorUid,
        actorName: actorName,
      );
      _actionState = const AsyncState.success(null);
      notifyListeners();
      return true;
    } catch (e) {
      _actionState = AsyncState.error('Failed to mark order delivered: $e');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
