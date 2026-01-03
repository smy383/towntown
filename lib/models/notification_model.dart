import 'package:cloud_firestore/cloud_firestore.dart';

/// 알림 타입
enum NotificationType {
  membershipApproved,    // 주민 신청 승인됨 (집 짓기 필요)
  membershipRejected,    // 주민 신청 거절됨
  membershipExpired,     // 집 짓기 기한 만료
  houseCompleted,        // 집 짓기 완료 (주민 확정)
  villageInvitation,     // 마을 초대
  general,               // 일반 알림
}

/// 알림 모델
class NotificationModel {
  final String id;
  final String userId;           // 알림 받는 사용자
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  // 관련 데이터 (마을 ID, 요청 ID 등)
  final String? villageId;
  final String? villageName;
  final String? requestId;
  final double? houseX;
  final double? houseY;
  final DateTime? deadline;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.villageId,
    this.villageName,
    this.requestId,
    this.houseX,
    this.houseY,
    this.deadline,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      villageId: data['villageId'],
      villageName: data['villageName'],
      requestId: data['requestId'],
      houseX: (data['houseX'] as num?)?.toDouble(),
      houseY: (data['houseY'] as num?)?.toDouble(),
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'villageId': villageId,
      'villageName': villageName,
      'requestId': requestId,
      'houseX': houseX,
      'houseY': houseY,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? villageId,
    String? villageName,
    String? requestId,
    double? houseX,
    double? houseY,
    DateTime? deadline,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      requestId: requestId ?? this.requestId,
      houseX: houseX ?? this.houseX,
      houseY: houseY ?? this.houseY,
      deadline: deadline ?? this.deadline,
    );
  }
}
