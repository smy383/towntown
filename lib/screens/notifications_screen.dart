import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import 'member_house_design_screen.dart';

/// 알림 화면
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final notifications = await _notificationService.getNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    await _notificationService.markAllAsRead(userId);
    _loadNotifications();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    // 읽음 처리
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    // 집 짓기 알림인 경우
    if (notification.type == NotificationType.membershipApproved &&
        notification.villageId != null &&
        notification.houseX != null &&
        notification.houseY != null &&
        notification.deadline != null &&
        notification.deadline!.isAfter(DateTime.now())) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberHouseDesignScreen(
              villageId: notification.villageId!,
              villageName: notification.villageName ?? '',
              requestId: notification.requestId ?? '',
              houseX: notification.houseX!,
              houseY: notification.houseY!,
              deadline: notification.deadline!,
            ),
          ),
        ).then((_) => _loadNotifications());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          l10n.notificationTitle,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n.markAllRead,
                style: const TextStyle(color: Colors.cyanAccent),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notificationEmpty,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: Colors.cyanAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () => _onNotificationTap(notification),
                      );
                    },
                  ),
                ),
    );
  }
}

/// 알림 카드
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    // 알림 타입에 따른 스타일
    Color iconColor;
    IconData iconData;
    bool showAction = false;

    switch (notification.type) {
      case NotificationType.membershipApproved:
        iconColor = Colors.greenAccent;
        iconData = Icons.check_circle;
        // 기한이 남아있으면 액션 버튼 표시
        showAction = notification.deadline != null &&
            notification.deadline!.isAfter(DateTime.now());
        break;
      case NotificationType.membershipRejected:
        iconColor = Colors.redAccent;
        iconData = Icons.cancel;
        break;
      case NotificationType.membershipExpired:
        iconColor = Colors.orangeAccent;
        iconData = Icons.timer_off;
        break;
      case NotificationType.houseCompleted:
        iconColor = Colors.cyanAccent;
        iconData = Icons.home;
        break;
      case NotificationType.villageInvitation:
        iconColor = Colors.pinkAccent;
        iconData = Icons.mail;
      case NotificationType.general:
        iconColor = Colors.grey;
        iconData = Icons.notifications;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.grey[900]
              : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[800]!
                : iconColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.grey[400]
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(
                color: notification.isRead
                    ? Colors.grey[500]
                    : Colors.grey[300],
                fontSize: 13,
              ),
            ),

            // 집 짓기 액션 버튼
            if (showAction && notification.deadline != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // 남은 기간 표시
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.orangeAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDaysRemaining(notification.deadline!, l10n),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 집 짓기 버튼
                  ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                    icon: const Icon(Icons.home, size: 16),
                    label: Text(l10n.goToBuildHouse),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  String _getDaysRemaining(DateTime deadline, L10n l10n) {
    final remaining = deadline.difference(DateTime.now()).inDays;
    if (remaining <= 0) return l10n.deadlineExpired;
    return l10n.daysRemaining(remaining);
  }
}
