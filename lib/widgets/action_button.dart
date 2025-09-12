import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
                children:[Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                      children: [
                        Icon(icon,
                          color: Colors.green,
                          size: 20,
                        ),
                        Text(title,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ]
                  ),
                ),
                ]
            ),
          )
      );
  }
}