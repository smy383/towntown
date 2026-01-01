import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅 메시지 모델
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final MessageType type;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    MessageType? type,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// 메시지 타입
enum MessageType {
  text,     // 일반 텍스트
  image,    // 이미지 (추후)
  system,   // 시스템 메시지 (입장/퇴장 등)
}

/// 채팅방 모델
class ChatRoom {
  final String id;
  final ChatRoomType type;
  final List<String> memberIds;
  final Map<String, String> memberNames; // uid -> name
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final DateTime createdAt;
  final Map<String, int> unreadCount; // uid -> unread count

  // 그룹 채팅용
  final String? groupName;
  final String? groupImage;

  ChatRoom({
    required this.id,
    required this.type,
    required this.memberIds,
    required this.memberNames,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    required this.createdAt,
    this.unreadCount = const {},
    this.groupName,
    this.groupImage,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatRoomType.direct,
      ),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastSenderId: data['lastSenderId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      groupName: data['groupName'],
      groupImage: data['groupImage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'lastSenderId': lastSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadCount': unreadCount,
      'groupName': groupName,
      'groupImage': groupImage,
    };
  }

  /// 1:1 채팅에서 상대방 이름 가져오기
  String getOtherMemberName(String myUid) {
    if (type == ChatRoomType.group) {
      return groupName ?? '그룹 채팅';
    }
    final otherUid = memberIds.firstWhere(
      (id) => id != myUid,
      orElse: () => '',
    );
    return memberNames[otherUid] ?? '알 수 없음';
  }

  /// 읽지 않은 메시지 수
  int getUnreadCount(String uid) {
    return unreadCount[uid] ?? 0;
  }

  ChatRoom copyWith({
    String? id,
    ChatRoomType? type,
    List<String>? memberIds,
    Map<String, String>? memberNames,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderId,
    DateTime? createdAt,
    Map<String, int>? unreadCount,
    String? groupName,
    String? groupImage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
    );
  }
}

/// 채팅방 타입
enum ChatRoomType {
  direct,   // 1:1 채팅
  group,    // 그룹 채팅
  village,  // 마을 채팅 (추후)
}
