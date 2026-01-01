import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

/// 채팅 서비스 - 채팅방 및 메시지 관리
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 채팅방 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _chatRoomsRef =>
      _firestore.collection('chatRooms');

  /// 메시지 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _messagesRef(String roomId) =>
      _chatRoomsRef.doc(roomId).collection('messages');

  // ============================================================
  // 채팅방 관련 메서드
  // ============================================================

  /// 1:1 채팅방 생성 또는 기존 채팅방 반환
  Future<ChatRoom> getOrCreateDirectChat({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
  }) async {
    // 기존 1:1 채팅방 검색
    final existingRoom = await _findDirectChatRoom(myUid, otherUid);
    if (existingRoom != null) {
      return existingRoom;
    }

    // 새 채팅방 생성
    final roomData = {
      'type': ChatRoomType.direct.name,
      'memberIds': [myUid, otherUid],
      'memberNames': {
        myUid: myName,
        otherUid: otherName,
      },
      'lastMessage': null,
      'lastMessageAt': null,
      'lastSenderId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        myUid: 0,
        otherUid: 0,
      },
      'groupName': null,
      'groupImage': null,
    };

    final docRef = await _chatRoomsRef.add(roomData);
    final doc = await docRef.get();
    return ChatRoom.fromFirestore(doc);
  }

  /// 기존 1:1 채팅방 검색
  Future<ChatRoom?> _findDirectChatRoom(String uid1, String uid2) async {
    final query = await _chatRoomsRef
        .where('type', isEqualTo: ChatRoomType.direct.name)
        .where('memberIds', arrayContains: uid1)
        .get();

    for (final doc in query.docs) {
      final room = ChatRoom.fromFirestore(doc);
      if (room.memberIds.contains(uid2)) {
        return room;
      }
    }
    return null;
  }

  /// 그룹 채팅방 생성
  Future<ChatRoom> createGroupChat({
    required String creatorUid,
    required String creatorName,
    required String groupName,
    required List<String> memberUids,
    required Map<String, String> memberNames,
    String? groupImage,
  }) async {
    // 생성자도 멤버에 포함
    final allMembers = [creatorUid, ...memberUids.where((uid) => uid != creatorUid)];
    final allNames = {creatorUid: creatorName, ...memberNames};

    final unreadCount = <String, int>{};
    for (final uid in allMembers) {
      unreadCount[uid] = 0;
    }

    final roomData = {
      'type': ChatRoomType.group.name,
      'memberIds': allMembers,
      'memberNames': allNames,
      'lastMessage': null,
      'lastMessageAt': null,
      'lastSenderId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'groupName': groupName,
      'groupImage': groupImage,
    };

    final docRef = await _chatRoomsRef.add(roomData);
    final doc = await docRef.get();
    return ChatRoom.fromFirestore(doc);
  }

  /// 내 채팅방 목록 스트림
  Stream<List<ChatRoom>> myChatRoomsStream(String uid) {
    return _chatRoomsRef
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  /// 채팅방 정보 가져오기
  Future<ChatRoom?> getChatRoom(String roomId) async {
    final doc = await _chatRoomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return ChatRoom.fromFirestore(doc);
  }

  /// 채팅방 나가기
  Future<void> leaveChatRoom({
    required String roomId,
    required String uid,
  }) async {
    final doc = await _chatRoomsRef.doc(roomId).get();
    if (!doc.exists) return;

    final room = ChatRoom.fromFirestore(doc);

    // 멤버에서 제거
    final newMemberIds = room.memberIds.where((id) => id != uid).toList();
    final newMemberNames = Map<String, String>.from(room.memberNames)..remove(uid);
    final newUnreadCount = Map<String, int>.from(room.unreadCount)..remove(uid);

    // 남은 멤버가 없으면 채팅방 삭제
    if (newMemberIds.isEmpty) {
      await _deleteChatRoom(roomId);
      return;
    }

    // 멤버 업데이트
    await _chatRoomsRef.doc(roomId).update({
      'memberIds': newMemberIds,
      'memberNames': newMemberNames,
      'unreadCount': newUnreadCount,
    });

    // 시스템 메시지 추가
    await _sendSystemMessage(
      roomId: roomId,
      content: '${room.memberNames[uid] ?? "알 수 없음"}님이 나갔습니다.',
    );
  }

  /// 채팅방 삭제 (모든 메시지 포함)
  Future<void> _deleteChatRoom(String roomId) async {
    // 메시지 삭제
    final messages = await _messagesRef(roomId).get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    // 채팅방 삭제
    await _chatRoomsRef.doc(roomId).delete();
  }

  // ============================================================
  // 메시지 관련 메서드
  // ============================================================

  /// 메시지 전송
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type.name,
      'isRead': false,
    };

    // 메시지 추가
    final docRef = await _messagesRef(roomId).add(messageData);

    // 채팅방 정보 업데이트 (마지막 메시지, 읽지 않은 수)
    final roomDoc = await _chatRoomsRef.doc(roomId).get();
    if (roomDoc.exists) {
      final room = ChatRoom.fromFirestore(roomDoc);
      final newUnreadCount = Map<String, int>.from(room.unreadCount);

      // 보낸 사람 제외 모든 멤버의 읽지 않은 수 증가
      for (final memberId in room.memberIds) {
        if (memberId != senderId) {
          newUnreadCount[memberId] = (newUnreadCount[memberId] ?? 0) + 1;
        }
      }

      await _chatRoomsRef.doc(roomId).update({
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount': newUnreadCount,
      });
    }

    final doc = await docRef.get();
    return ChatMessage.fromFirestore(doc);
  }

  /// 시스템 메시지 전송 (입장/퇴장 등)
  Future<void> _sendSystemMessage({
    required String roomId,
    required String content,
  }) async {
    await _messagesRef(roomId).add({
      'senderId': 'system',
      'senderName': 'System',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'type': MessageType.system.name,
      'isRead': true,
    });

    await _chatRoomsRef.doc(roomId).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': 'system',
    });
  }

  /// 메시지 목록 스트림 (실시간)
  Stream<List<ChatMessage>> messagesStream(String roomId) {
    return _messagesRef(roomId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// 읽지 않은 메시지 읽음 처리
  Future<void> markAsRead({
    required String roomId,
    required String uid,
  }) async {
    // 읽지 않은 수 0으로 설정
    await _chatRoomsRef.doc(roomId).update({
      'unreadCount.$uid': 0,
    });
  }

  /// 전체 읽지 않은 메시지 수 스트림
  Stream<int> totalUnreadCountStream(String uid) {
    return _chatRoomsRef
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final room = ChatRoom.fromFirestore(doc);
            total += room.getUnreadCount(uid);
          }
          return total;
        });
  }

  // ============================================================
  // 그룹 채팅 관리 메서드
  // ============================================================

  /// 그룹 채팅에 멤버 추가
  Future<void> addMemberToGroup({
    required String roomId,
    required String newUid,
    required String newName,
    required String addedByName,
  }) async {
    await _chatRoomsRef.doc(roomId).update({
      'memberIds': FieldValue.arrayUnion([newUid]),
      'memberNames.$newUid': newName,
      'unreadCount.$newUid': 0,
    });

    await _sendSystemMessage(
      roomId: roomId,
      content: '$addedByName님이 $newName님을 초대했습니다.',
    );
  }

  /// 그룹 채팅 이름 변경
  Future<void> updateGroupName({
    required String roomId,
    required String newName,
  }) async {
    await _chatRoomsRef.doc(roomId).update({
      'groupName': newName,
    });
  }

  /// 그룹 채팅 이미지 변경
  Future<void> updateGroupImage({
    required String roomId,
    required String? imageUrl,
  }) async {
    await _chatRoomsRef.doc(roomId).update({
      'groupImage': imageUrl,
    });
  }
}
