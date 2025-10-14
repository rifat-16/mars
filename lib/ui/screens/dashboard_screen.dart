import 'package:Mars/ui/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/role_controller.dart';

class DashboardScreen extends StatefulWidget {
  final String currentUserPhone;
  const DashboardScreen({super.key, required this.currentUserPhone});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    checkUserRole();

  }

  Future<void> checkUserRole() async {
    final role = await RoleController.getUserRole();
    setState(() {
      isAdmin = role == 'Owner';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      return isAdmin!
          ? const AdminDashboardScreen()
          : UserDashboardScreen(phoneNumber: widget.currentUserPhone);
    }
  }
}

// ---------------------- Admin Dashboard ----------------------
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalOrdersCount = 0;
  double totalOrdersAmount = 0;
  int totalPaymentsCount = 0;
  double totalPaymentsAmount = 0;

  // For Due Card
  double dueAmount = 0;
  bool ordersEmpty = false;
  bool paymentsEmpty = false;

  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> recentPayments = [];

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final ordersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();
    final paymentsSnapshot =
        await FirebaseFirestore.instance.collection('payments').get();

    print('Admin orders fetched: ${ordersSnapshot.docs.length}');
    for (var doc in ordersSnapshot.docs) {
      print('Order doc id: ${doc.id}, data: ${doc.data()}');
    }
    print('Admin payments fetched: ${paymentsSnapshot.docs.length}');
    for (var doc in paymentsSnapshot.docs) {
      print('Payment doc id: ${doc.id}, data: ${doc.data()}');
    }

    // Calculate orders totals
    double ordersAmount = 0;
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      // Use totalAmount if present, else fallback to amount
      double amount = 0.0;
      if (data.containsKey('totalAmount') && data['totalAmount'] != null) {
        amount = (data['totalAmount'] as num).toDouble();
      } else if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      ordersAmount += amount;
    }

    // Calculate payments totals
    double paymentsAmount = 0;
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      // Use correct amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      paymentsAmount += amount;
    }

    // Filter recent orders and payments (last 7 days)
    List<Map<String, dynamic>> filteredOrders = [];
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      // Flexible date field
      var timestamp = data['date'] ?? data['createdAt'] ?? data['orderDate'];
      DateTime? orderDate;
      if (timestamp is Timestamp) {
        orderDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        orderDate = timestamp;
      }
      // Flexible amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      } else if (data.containsKey('totalAmount') && data['totalAmount'] != null) {
        amount = (data['totalAmount'] as num).toDouble();
      } else if (data.containsKey('paymentAmount') && data['paymentAmount'] != null) {
        amount = (data['paymentAmount'] as num).toDouble();
      }
      if (orderDate != null && orderDate.isAfter(sevenDaysAgo)) {
        filteredOrders.add({
          'date': orderDate,
          'amount': amount,
          'customerName': data['customerName'] ?? 'Unknown',
        });
      }
    }
    filteredOrders.sort((a, b) => b['date'].compareTo(a['date']));

    List<Map<String, dynamic>> filteredPayments = [];
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      // Use correct date field
      var timestamp = data['timestamp'];
      DateTime? paymentDate;
      if (timestamp is Timestamp) {
        paymentDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        paymentDate = timestamp;
      }
      // Use correct amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      // Use correct phone field
      String phone = data['pharmacyPhone'] ?? 'Unknown';
      if (paymentDate != null && paymentDate.isAfter(sevenDaysAgo)) {
        filteredPayments.add({
          'date': paymentDate,
          'amount': amount,
          'pharmacyPhone': phone,
        });
      }
    }
    filteredPayments.sort((a, b) => b['date'].compareTo(a['date']));

    print('Admin filtered recent payments: ${filteredPayments.length}');
    for (var p in filteredPayments) {
      print('Recent Payment: $p');
    }

    setState(() {
      totalOrdersCount = ordersSnapshot.docs.length;
      totalOrdersAmount = ordersAmount;
      totalPaymentsCount = paymentsSnapshot.docs.length;
      totalPaymentsAmount = paymentsAmount;
      dueAmount = ordersAmount - paymentsAmount;
      ordersEmpty = ordersSnapshot.docs.isEmpty;
      paymentsEmpty = paymentsSnapshot.docs.isEmpty;
      recentOrders = filteredOrders;
      recentPayments = filteredPayments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: MainAppBar(title: 'Admin Dashboard', icon: Icons.dashboard),
      body: RefreshIndicator(
        onRefresh: fetchAdminData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(),
              const SizedBox(height: 28),
              Text(
                "Recent Orders (Last 7 days)",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: 'Montserrat',
                    ),
              ),
              const SizedBox(height: 10),
              recentOrders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "No recent orders.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15.5),
                      ),
                    )
                  : ModernCardList(
                      items: recentOrders,
                      isOrder: true,
                    ),
              const SizedBox(height: 28),
              Text(
                "Recent Payments (Last 7 days)",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: 'Montserrat',
                    ),
              ),
              const SizedBox(height: 10),
              recentPayments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "No recent payments.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15.5),
                      ),
                    )
                  : ModernCardList(
                      items: recentPayments,
                      isOrder: false,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    // Modern, larger cards with spacing
    return Column(
      children: [
        StatCard(
          title: "Orders",
          value: ordersEmpty ? 0 : totalOrdersCount.toDouble(),
          icon: Icons.shopping_bag,
          gradientColors: [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
          sections: ordersEmpty
              ? [
                  const StatSection(
                    label: "Total Amount",
                    value: "No Data",
                  ),
                ]
              : [
                  StatSection(
                    label: "Total Amount",
                    value: "\$${totalOrdersAmount.toStringAsFixed(2)}",
                  ),
                ],
        ),
        const SizedBox(height: 22),
        StatCard(
          title: "Payments",
          value: paymentsEmpty ? 0 : totalPaymentsCount.toDouble(),
          icon: Icons.attach_money,
          gradientColors: [const Color(0xFF43cea2), const Color(0xFF185a9d)],
          sections: paymentsEmpty
              ? [
                  const StatSection(
                    label: "Total Amount",
                    value: "No Data",
                  ),
                ]
              : [
                  StatSection(
                    label: "Total Amount",
                    value: "\$${totalPaymentsAmount.toStringAsFixed(2)}",
                  ),
                ],
        ),
        const SizedBox(height: 22),
        StatCard(
          title: "Due",
          value: dueAmount >= 0 ? dueAmount : 0,
          icon: Icons.warning_amber_rounded,
          gradientColors: [const Color(0xFFee9ca7), const Color(0xFFffdde1)],
          sections: [
            StatSection(
              label: "Due Amount",
              value: dueAmount >= 0 ? "\$${dueAmount.toStringAsFixed(2)}" : "No Data",
            ),
          ],
          highlightDue: dueAmount > 0,
        ),
      ],
    );
  }

}

// ---------------------- User Dashboard ----------------------
class UserDashboardScreen extends StatefulWidget {
  final String phoneNumber;
  const UserDashboardScreen({super.key, required this.phoneNumber});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int totalOrdersCount = 0;
  double totalOrdersAmount = 0;
  int totalPaymentsCount = 0;
  double totalPaymentsAmount = 0;
  double dueAmount = 0;
  bool ordersEmpty = false;
  bool paymentsEmpty = false;

  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> recentPayments = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('phoneNumber', isEqualTo: widget.phoneNumber)
        .get();
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('pharmacyPhone', isEqualTo: widget.phoneNumber)
        .get();

    print('User orders fetched: ${ordersSnapshot.docs.length}');
    for (var doc in ordersSnapshot.docs) {
      print('Order doc id: ${doc.id}, data: ${doc.data()}');
    }
    print('User payments fetched: ${paymentsSnapshot.docs.length}');
    for (var doc in paymentsSnapshot.docs) {
      print('Payment doc id: ${doc.id}, data: ${doc.data()}');
    }

    // Calculate orders totals
    double ordersAmount = 0;
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      // Use totalAmount if present, else fallback to amount
      double amount = 0.0;
      if (data.containsKey('totalAmount') && data['totalAmount'] != null) {
        amount = (data['totalAmount'] as num).toDouble();
      } else if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      ordersAmount += amount;
    }

    // Calculate payments totals
    double paymentsAmount = 0;
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      // Use correct amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      paymentsAmount += amount;
    }

    // Filter recent orders and payments (last 7 days)
    List<Map<String, dynamic>> filteredOrders = [];
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      // Flexible date field
      var timestamp = data['date'] ?? data['createdAt'] ?? data['orderDate'];
      DateTime? orderDate;
      if (timestamp is Timestamp) {
        orderDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        orderDate = timestamp;
      }
      // Flexible amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      } else if (data.containsKey('totalAmount') && data['totalAmount'] != null) {
        amount = (data['totalAmount'] as num).toDouble();
      } else if (data.containsKey('paymentAmount') && data['paymentAmount'] != null) {
        amount = (data['paymentAmount'] as num).toDouble();
      }
      if (orderDate != null && orderDate.isAfter(sevenDaysAgo)) {
        filteredOrders.add({
          'date': orderDate,
          'amount': amount,
          'customerName': data['customerName'] ?? 'Unknown',
        });
      }
    }
    filteredOrders.sort((a, b) => b['date'].compareTo(a['date']));

    List<Map<String, dynamic>> filteredPayments = [];
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      // Use correct date field
      var timestamp = data['timestamp'];
      DateTime? paymentDate;
      if (timestamp is Timestamp) {
        paymentDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        paymentDate = timestamp;
      }
      // Use correct amount field
      double amount = 0.0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = (data['amount'] as num).toDouble();
      }
      // Use correct phone field
      String phone = data['pharmacyPhone'] ?? 'Unknown';
      if (paymentDate != null && paymentDate.isAfter(sevenDaysAgo)) {
        filteredPayments.add({
          'date': paymentDate,
          'amount': amount,
          'pharmacyPhone': phone,
        });
      }
    }
    filteredPayments.sort((a, b) => b['date'].compareTo(a['date']));

    print('User filtered recent payments: ${filteredPayments.length}');
    for (var p in filteredPayments) {
      print('Recent Payment: $p');
    }

    setState(() {
      totalOrdersCount = ordersSnapshot.docs.length;
      totalOrdersAmount = ordersAmount;
      totalPaymentsCount = paymentsSnapshot.docs.length;
      totalPaymentsAmount = paymentsAmount;
      dueAmount = ordersAmount - paymentsAmount;
      ordersEmpty = ordersSnapshot.docs.isEmpty;
      paymentsEmpty = paymentsSnapshot.docs.isEmpty;
      recentOrders = filteredOrders;
      recentPayments = filteredPayments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: MainAppBar(title: 'My Dashboard', icon: Icons.dashboard),
      body: RefreshIndicator(
        onRefresh: fetchUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(),
              const SizedBox(height: 28),
              Text(
                "Recent Orders (Last 7 days)",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: 'Montserrat',
                    ),
              ),
              const SizedBox(height: 10),
              recentOrders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "No recent orders.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15.5),
                      ),
                    )
                  : ModernCardList(
                      items: recentOrders,
                      isOrder: true,
                    ),
              const SizedBox(height: 28),
              Text(
                "Recent Payments (Last 7 days)",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: 'Montserrat',
                    ),
              ),
              const SizedBox(height: 10),
              recentPayments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "No recent payments.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15.5),
                      ),
                    )
                  : ModernCardList(
                      items: recentPayments,
                      isOrder: false,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    // Modern, larger cards with spacing
    return Column(
      children: [
        StatCard(
          title: "Orders",
          value: ordersEmpty ? 0 : totalOrdersCount.toDouble(),
          icon: Icons.shopping_bag,
          gradientColors: [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
          sections: ordersEmpty
              ? [
                  const StatSection(
                    label: "Total Amount",
                    value: "No Data",
                  ),
                ]
              : [
                  StatSection(
                    label: "Total Amount",
                    value: "\$${totalOrdersAmount.toStringAsFixed(2)}",
                  ),
                ],
        ),
        const SizedBox(height: 22),
        StatCard(
          title: "Payments",
          value: paymentsEmpty ? 0 : totalPaymentsCount.toDouble(),
          icon: Icons.attach_money,
          gradientColors: [const Color(0xFF43cea2), const Color(0xFF185a9d)],
          sections: paymentsEmpty
              ? [
                  const StatSection(
                    label: "Total Amount",
                    value: "No Data",
                  ),
                ]
              : [
                  StatSection(
                    label: "Total Amount",
                    value: "\$${totalPaymentsAmount.toStringAsFixed(2)}",
                  ),
                ],
        ),
        const SizedBox(height: 22),
        StatCard(
          title: "Due",
          value: dueAmount >= 0 ? dueAmount : 0,
          icon: Icons.warning_amber_rounded,
          gradientColors: [const Color(0xFFee9ca7), const Color(0xFFffdde1)],
          sections: [
            StatSection(
              label: "Due Amount",
              value: dueAmount >= 0 ? "\$${dueAmount.toStringAsFixed(2)}" : "No Data",
            ),
          ],
          highlightDue: dueAmount > 0,
        ),
      ],
    );
  }

}

// ---------------------- Modern Widgets ----------------------
class StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final List<Color> gradientColors;
  final List<StatSection> sections;
  final bool highlightDue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.sections,
    this.highlightDue = false,
  });

  @override
  Widget build(BuildContext context) {
    // Modern, larger, gradient, soft shadow, rounded, icon in circle, animated value, modern font.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.19),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 30,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.96),
                        letterSpacing: 0.2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Animated Value
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value),
                  duration: const Duration(milliseconds: 950),
                  builder: (context, val, child) {
                    return Text(
                      val.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.6,
                        fontFamily: 'Montserrat',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 7),
              // Subtitle (sections)
              ...sections.map((s) {
                final isDueAmount = highlightDue && s.label.toLowerCase().contains('due');
                return Padding(
                  padding: const EdgeInsets.only(top: 3.5),
                  child: Row(
                    children: [
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.13,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 17,
                          color: isDueAmount ? Colors.red[400] : Colors.white.withOpacity(0.99),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.21,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class StatSection {
  final String label;
  final String value;
  const StatSection({required this.label, required this.value});
}

class ModernCardList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isOrder;
  const ModernCardList({super.key, required this.items, required this.isOrder});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final date = item['date'] as DateTime?;
        final dateFormatted = date != null
            ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
            : "";
        final title = isOrder ? (item['customerName'] ?? 'Unknown') : (item['pharmacyPhone'] ?? 'Unknown');
        final trailing = "\$${(item['amount'] as num).toStringAsFixed(2)}";
        return Material(
          color: Colors.white,
          elevation: 2.5,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black.withOpacity(0.10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isOrder ? Colors.blue[100] : Colors.teal[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOrder ? Icons.shopping_bag : Icons.attach_money,
                    color: isOrder ? Colors.blue[700] : Colors.teal[700],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 13.5, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: isOrder ? Colors.blue[600] : Colors.teal[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
