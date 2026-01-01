import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../l10n/app_localizations.dart';

/// 채팅방 목록 화면
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    if (_myUid == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(l10n.chatTitle),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Text(
            l10n.loginRequired,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.chatTitle,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.myChatRoomsStream(_myUid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noChatRooms,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ChatRoomTile(
                room: room,
                myUid: _myUid!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(room: room),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 채팅방 타일 위젯
class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String myUid;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.room,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = room.getUnreadCount(myUid);
    final displayName = room.getOtherMemberName(myUid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unreadCount > 0
              ? Colors.cyanAccent.withValues(alpha: 0.5)
              : Colors.grey[800]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            room.type == ChatRoomType.group
                ? Icons.group
                : Icons.person,
            color: Colors.cyanAccent,
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: room.lastMessage != null
            ? Text(
                room.lastMessage!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (room.lastMessageAt != null)
              Text(
                _formatTime(room.lastMessageAt!),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${dateTime.month}/${dateTime.day}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// 채팅방 화면
class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;
  final String? _myName = FirebaseAuth.instance.currentUser?.displayName;

  @override
  void initState() {
    super.initState();
    // 채팅방 진입 시 읽음 처리
    if (_myUid != null) {
      _chatService.markAsRead(roomId: widget.room.id, uid: _myUid!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _myUid == null) return;

    _messageController.clear();

    await _chatService.sendMessage(
      roomId: widget.room.id,
      senderId: _myUid!,
      senderName: _myName ?? 'Unknown',
      content: content,
    );

    // 스크롤 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final displayName = widget.room.getOtherMemberName(_myUid ?? '');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.messagesStream(widget.room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noMessages,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                // 읽음 처리
                if (_myUid != null) {
                  _chatService.markAsRead(roomId: widget.room.id, uid: _myUid!);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _myUid;
                    final isSystem = message.type == MessageType.system;

                    if (isSystem) {
                      return _SystemMessage(message: message);
                    }

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // 메시지 입력
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l10n.messageHint,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    final l10n = L10n.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: Text(
                  l10n.leaveChat,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showLeaveConfirmation(context);
                  if (confirm == true && _myUid != null) {
                    await _chatService.leaveChatRoom(
                      roomId: widget.room.id,
                      uid: _myUid!,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showLeaveConfirmation(BuildContext context) {
    final l10n = L10n.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            l10n.leaveChat,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            l10n.leaveChatConfirm,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.leave,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 시스템 메시지 위젯
class _SystemMessage extends StatelessWidget {
  final ChatMessage message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// 메시지 버블 위젯
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // 상대방 이름
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.cyanAccent : Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
