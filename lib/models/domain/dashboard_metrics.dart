class DashboardMetrics {
  final int totalOrdersCount;
  final double totalOrdersAmount;
  final int totalPaymentsCount;
  final double totalPaymentsAmount;
  final double dueAmount;

  const DashboardMetrics({
    required this.totalOrdersCount,
    required this.totalOrdersAmount,
    required this.totalPaymentsCount,
    required this.totalPaymentsAmount,
    required this.dueAmount,
  });

  const DashboardMetrics.empty()
    : totalOrdersCount = 0,
      totalOrdersAmount = 0,
      totalPaymentsCount = 0,
      totalPaymentsAmount = 0,
      dueAmount = 0;
}
