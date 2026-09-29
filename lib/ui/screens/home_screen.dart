import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final role = session.currentUser?.position ?? '';
    final firstName = session.currentUser?.firstName ?? 'User';
    final fullName = session.currentUser?.fullName.isNotEmpty == true
        ? session.currentUser!.fullName
        : firstName;
    final phone = session.currentUser?.phone ?? '';

    final actions = _buildActions(
      context: context,
      role: role,
      currentUserPhone: phone,
    );

    const crossAxisCount = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      appBar: const MainAppBar(title: 'Home', icon: Icons.home_rounded),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: _WelcomePanel(
                fullName: fullName,
                role: role,
                phone: phone,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1A3A2A),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    role.isEmpty ? 'Role Pending' : role,
                    style: const TextStyle(
                      color: Color(0xFF4A7460),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            sliver: SliverGrid.builder(
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _ActionCard(action: action);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        onTapHome: () {},
        onTapOrders: () => Navigator.pushNamed(context, AppRoutes.orders),
        onTapProfile: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
    );
  }

  List<_HomeAction> _buildActions({
    required BuildContext context,
    required String role,
    required String currentUserPhone,
  }) {
    bool owner() => role == 'Owner';
    bool managerOrOwner() => role == 'Owner' || role == 'Manager';

    final all = <_HomeAction>[
      _HomeAction(
        title: 'Medicine',
        icon: Icons.medical_services_rounded,
        colors: const [Color(0xFF2FA37C), Color(0xFF278D6B)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.medicine),
      ),
      _HomeAction(
        title: 'Orders',
        icon: Icons.shopping_cart_checkout_rounded,
        colors: const [Color(0xFF2F9CD8), Color(0xFF287EB0)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
      ),
      _HomeAction(
        title: 'Dashboard',
        icon: Icons.grid_view_rounded,
        colors: const [Color(0xFF6EAA56), Color(0xFF598E44)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                currentUserPhone: currentUserPhone,
                currentUserRole: role,
              ),
            ),
          );
        },
      ),
      _HomeAction(
        title: 'Events New',
        icon: Icons.event_note_rounded,
        colors: const [Color(0xFFCE8A2A), Color(0xFFB6701F)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.eventsV3),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Employee',
        icon: Icons.people_alt_rounded,
        colors: const [Color(0xFF2AABA5), Color(0xFF1D8A85)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.employee),
        enabled: owner(),
      ),
      _HomeAction(
        title: 'Inventory',
        icon: Icons.inventory_2_rounded,
        colors: const [Color(0xFFEA675D), Color(0xFFD34E43)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Invoice',
        icon: Icons.post_add_rounded,
        colors: const [Color(0xFF6580D8), Color(0xFF4E66BE)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.createOrder),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Production',
        icon: Icons.precision_manufacturing_rounded,
        colors: const [Color(0xFFFF8B5E), Color(0xFFE26D40)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.productionDetails),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Add Production',
        icon: Icons.add_box_rounded,
        colors: const [Color(0xFFAA9287), Color(0xFF8F786D)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.addProduction),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Add Medicine',
        icon: Icons.add_circle_outline_rounded,
        colors: const [Color(0xFFE05A8F), Color(0xFFC84578)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.addMedicine),
        enabled: owner(),
      ),
      _HomeAction(
        title: 'Customers',
        icon: Icons.local_pharmacy_rounded,
        colors: const [Color(0xFF6EBB6F), Color(0xFF5BA25D)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.pharmacyList),
        enabled: managerOrOwner(),
      ),
      _HomeAction(
        title: 'Payments',
        icon: Icons.payments_rounded,
        colors: const [Color(0xFF88A0B0), Color(0xFF6F8796)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.paymentReceived),
        enabled: owner(),
      ),
    ];

    return all.where((item) => item.enabled).toList();
  }
}

class _WelcomePanel extends StatelessWidget {
  final String fullName;
  final String role;
  final String phone;

  const _WelcomePanel({
    required this.fullName,
    required this.role,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final shortName = fullName.split(' ').first;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3AA06F), Color(0xFF6DBA72)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x295A9E75),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo-removebg-preview.png',
                height: 52,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $shortName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.isEmpty ? 'Role not set yet' : role,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _HomeAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: action.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: action.colors.last.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final VoidCallback onTapHome;
  final VoidCallback onTapOrders;
  final VoidCallback onTapProfile;

  const _BottomNav({
    required this.onTapHome,
    required this.onTapOrders,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2E8B57),
          unselectedItemColor: const Color(0xFF8E8E8E),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          onTap: (index) {
            switch (index) {
              case 0:
                onTapHome();
                break;
              case 1:
                onTapOrders();
                break;
              case 2:
                onTapProfile();
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool enabled;

  const _HomeAction({
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.enabled = true,
  });
}
