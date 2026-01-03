import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// 알림 서비스
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 알림 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// 알림 생성
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _notificationsRef.add(notification.toFirestore());
      debugPrint('[NotificationService] Created notification for ${notification.userId}');
    } catch (e) {
      debugPrint('[NotificationService] Error creating notification: $e');
    }
  }

  /// 주민 승인 알림 생성
  Future<void> notifyMembershipApproved({
    required String userId,
    required String villageId,
    required String villageName,
    required String requestId,
    required double houseX,
    required double houseY,
    required DateTime deadline,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: NotificationType.membershipApproved,
      title: '주민 신청 승인',
      message: '$villageName 마을의 주민이 되었습니다! 7일 내에 집을 지어주세요.',
      createdAt: DateTime.now(),
      villageId: villageId,
      villageName: villageName,
      requestId: requestId,
      houseX: houseX,
      houseY: houseY,
      deadline: deadline,
    );
    await createNotification(notification);
  }

  /// 주민 거절 알림 생성
  Future<void> notifyMembershipRejected({
    required String userId,
    required String villageName,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: NotificationType.membershipRejected,
      title: '주민 신청 거절',
      message: '$villageName 마을의 주민 신청이 거절되었습니다.',
      createdAt: DateTime.now(),
      villageName: villageName,
    );
    await createNotification(notification);
  }

  /// 기한 만료 알림 생성
  Future<void> notifyMembershipExpired({
    required String userId,
    required String villageName,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: NotificationType.membershipExpired,
      title: '집 짓기 기한 만료',
      message: '$villageName 마을의 집 짓기 기한이 만료되어 주민 자격이 취소되었습니다.',
      createdAt: DateTime.now(),
      villageName: villageName,
    );
    await createNotification(notification);
  }

  /// 사용자의 알림 목록 가져오기
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[NotificationService] Error getting notifications: $e');
      return [];
    }
  }

  /// 읽지 않은 알림 개수
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[NotificationService] Error getting unread count: $e');
      return 0;
    }
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService] Error marking as read: $e');
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] Error marking all as read: $e');
    }
  }

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
    }
  }

  /// 알림 실시간 스트림
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// 읽지 않은 알림 스트림
  Stream<int> unreadCountStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 집 짓기 대기 중인 승인 알림 가져오기
  Future<List<NotificationModel>> getPendingHouseNotifications(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: NotificationType.membershipApproved.name)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((n) => n.deadline != null && n.deadline!.isAfter(DateTime.now()))
          .toList();
    } catch (e) {
      debugPrint('[NotificationService] Error getting pending house notifications: $e');
      return [];
    }
  }
}
