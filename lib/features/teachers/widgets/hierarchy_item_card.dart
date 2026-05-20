import 'package:flutter/material.dart';

class HierarchyItemCard extends StatelessWidget {
  const HierarchyItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
          child: Icon(leadingIcon, color: const Color(0xFF2563EB)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}