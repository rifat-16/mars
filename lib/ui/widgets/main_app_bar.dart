import 'package:flutter/material.dart';
import 'dart:ui';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final bool? showBackButton;

  const MainAppBar({
    Key? key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailingIcon,
    this.onTrailingPressed,
    this.showBackButton,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final bool _showBackButton = showBackButton ?? (title != 'Home');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  if (_showBackButton)
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                    ),
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (trailingIcon != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: onTrailingPressed,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(trailingIcon, color: Colors.white, size: 28),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}