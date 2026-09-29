import 'package:flutter/foundation.dart';

import '../core/state/async_state.dart';
import '../data/repositories/dashboard_repository.dart';
import '../models/domain/dashboard_metrics.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepository;

  DashboardProvider(this._dashboardRepository);

  AsyncState<DashboardMetrics> _state = const AsyncState.idle();

  AsyncState<DashboardMetrics> get state => _state;

  Future<void> refresh() async {
    _state = const AsyncState.loading();
    notifyListeners();

    try {
      final metrics = await _dashboardRepository.fetchMetrics();
      _state = AsyncState.success(metrics);
    } catch (e) {
      _state = AsyncState.error('Failed to load dashboard metrics: $e');
    }

    notifyListeners();
  }
}
