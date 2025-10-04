import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;
  final bool showBackButton;

  const MainAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
    this.showBackButton = true, // Home screen হলে false করতে হবে
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      title: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
