import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/features/departments/models/department_notification_model.dart';
import 'package:test/features/departments/providers/department_notification_provider.dart';
import 'package:test/features/departments/pages/justification_detail_page.dart';
import 'package:test/helpers/localization_helper.dart';

class DepartmentNotificationsPage extends StatefulWidget {
  const DepartmentNotificationsPage({required this.departmentId, super.key});

  final String departmentId;

  @override
  State<DepartmentNotificationsPage> createState() =>
      _DepartmentNotificationsPageState();
}

class _DepartmentNotificationsPageState
    extends State<DepartmentNotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when page is opened
    Future.microtask(() {
      context
          .read<DepartmentNotificationProvider>()
          .initializeDepartmentNotifications(widget.departmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F46E5)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('notifications'),
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<DepartmentNotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty || provider.unreadCount == 0) {
                return SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () => provider.markAllNotificationsAsRead(
                      widget.departmentId,
                    ),
                    child: Text(
                      context.tr('mark_all_read'),
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DepartmentNotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationItem(context, notification, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 40,
              color: Color(0xFFBBBCBD),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_notifications'),
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('all_caught_up'),
            style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    DepartmentNotificationModel notification,
    DepartmentNotificationProvider provider,
  ) {
    return GestureDetector(
      onTap: () async {
        // Mark as read when opened
        if (!notification.isRead) {
          await provider.markNotificationAsRead(notification.id);
        }

        // Navigate to justification detail
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JustificationDetailPage(
                justificationId: notification.justificationId,
                notificationId: notification.id,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFEEE5FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE4E7EC)
                : const Color(0xFF5A4CF0),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: notification.isRead
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF5A4CF0).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A4CF0),
                    shape: BoxShape.circle,
                  ),
                  child: notification.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            notification.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarPlaceholder(
                                notification.studentName,
                              );
                            },
                          ),
                        )
                      : _buildAvatarPlaceholder(notification.studentName),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: const Color(0xFF1D2939),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5A4CF0),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: const Color(0xFF98A2B3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.formattedTime,
                            style: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E5FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.subjectName,
                              style: const TextStyle(
                                color: Color(0xFF5A4CF0),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String studentName) {
    final initials = studentName.isNotEmpty
        ? studentName.split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : '?';

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}
