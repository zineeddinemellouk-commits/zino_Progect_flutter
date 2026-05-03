import 'package:flutter/material.dart';
import 'package:test/models/student_model.dart';

class StudentInfoCard extends StatelessWidget {
  const StudentInfoCard({
    super.key,
    required this.student,
    this.fallbackGroupName,
    this.onEdit,
    this.onDelete,
  });

  final StudentModel student;
  final String? fallbackGroupName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final groupName = (student.groupName?.trim().isNotEmpty == true)
        ? student.groupName!
        : (fallbackGroupName ?? student.groupId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Purple accent bar
          Container(
            width: 4,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Center(
                          child: Text(
                            student.fullName.isNotEmpty
                                ? student.fullName[0].toUpperCase()
                                : '',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          student.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('$groupName', const Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      if (student.age != null)
                        _chip('${student.age} yrs', const Color(0xFF2563EB)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
