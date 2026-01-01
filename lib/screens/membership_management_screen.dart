import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/village_service.dart';
import '../services/search_service.dart';
import '../models/village_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

/// 이장용 주민 관리 화면
class MembershipManagementScreen extends StatefulWidget {
  final String villageId;
  final String villageName;

  const MembershipManagementScreen({
    super.key,
    required this.villageId,
    required this.villageName,
  });

  @override
  State<MembershipManagementScreen> createState() => _MembershipManagementScreenState();
}

class _MembershipManagementScreenState extends State<MembershipManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VillageService _villageService = VillageService();

  List<MembershipRequest> _pendingRequests = [];
  List<Map<String, String>> _members = [];
  List<MembershipInvitation> _sentInvitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final requests = await _villageService.getPendingRequests(widget.villageId);
      final members = await _villageService.getMembersList(widget.villageId);
      final invitations = await _villageService.getSentInvitations(widget.villageId);

      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _members = members;
          _sentInvitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveRequest(MembershipRequest request) async {
    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.user?.uid;
    final l10n = L10n.of(context)!;

    if (ownerId == null) return;

    final success = await _villageService.approveMembership(
      villageId: widget.villageId,
      requestId: request.id,
      ownerId: ownerId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.membershipApproved),
          backgroundColor: Colors.greenAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  Future<void> _rejectRequest(MembershipRequest request) async {
    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.user?.uid;
    final l10n = L10n.of(context)!;

    if (ownerId == null) return;

    final success = await _villageService.rejectMembership(
      villageId: widget.villageId,
      requestId: request.id,
      ownerId: ownerId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.membershipRejected),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  Future<void> _removeMember(String memberId) async {
    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.user?.uid;
    final l10n = L10n.of(context)!;

    if (ownerId == null) return;

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.membershipRemove, style: const TextStyle(color: Colors.white)),
        content: Text('정말 이 주민을 제명하시겠습니까?', style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.membershipRemove, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _villageService.removeMember(
      villageId: widget.villageId,
      memberId: memberId,
      ownerId: ownerId,
    );

    if (success && mounted) {
      _loadData();
    }
  }

  Future<void> _cancelInvitation(MembershipInvitation invitation) async {
    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.user?.uid;
    final l10n = L10n.of(context)!;

    if (ownerId == null) return;

    final success = await _villageService.cancelInvitation(
      invitationId: invitation.id,
      ownerId: ownerId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invitationCancelled),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InviteUserSheet(
        villageId: widget.villageId,
        villageName: widget.villageName,
        onInvited: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.villageName,
          style: const TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.membershipRequests),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: l10n.members),
            Tab(text: l10n.sentInvitations),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(l10n),
                _buildMembersTab(l10n),
                _buildInvitationsTab(l10n),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteDialog,
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
    );
  }

  Widget _buildRequestsTab(L10n l10n) {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              l10n.membershipNoRequests,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _RequestCard(
          request: request,
          onApprove: () => _approveRequest(request),
          onReject: () => _rejectRequest(request),
        );
      },
    );
  }

  Widget _buildMembersTab(L10n l10n) {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              '아직 주민이 없습니다',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _MemberCard(
          name: member['name'] ?? 'Unknown',
          uid: member['uid'] ?? '',
          onRemove: () => _removeMember(member['uid'] ?? ''),
        );
      },
    );
  }

  Widget _buildInvitationsTab(L10n l10n) {
    if (_sentInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              '보낸 초대가 없습니다',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _sentInvitations[index];
        return _InvitationCard(
          invitation: invitation,
          onCancel: () => _cancelInvitation(invitation),
        );
      },
    );
  }
}

/// 가입 신청 카드
class _RequestCard extends StatelessWidget {
  final MembershipRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.cyanAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onReject,
            icon: const Icon(Icons.close, color: Colors.redAccent),
            tooltip: l10n.membershipReject,
          ),
          IconButton(
            onPressed: onApprove,
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            tooltip: l10n.membershipApprove,
          ),
        ],
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
}

/// 주민 카드
class _MemberCard extends StatelessWidget {
  final String name;
  final String uid;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.name,
    required this.uid,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.person_remove, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

/// 보낸 초대 카드
class _InvitationCard extends StatelessWidget {
  final MembershipInvitation invitation;
  final VoidCallback onCancel;

  const _InvitationCard({
    required this.invitation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_outline, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.inviteeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.membershipPending,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(l10n.invitationCancel, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

/// 사용자 초대 시트
class _InviteUserSheet extends StatefulWidget {
  final String villageId;
  final String villageName;
  final VoidCallback onInvited;

  const _InviteUserSheet({
    required this.villageId,
    required this.villageName,
    required this.onInvited,
  });

  @override
  State<_InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends State<_InviteUserSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final VillageService _villageService = VillageService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final myUid = authProvider.user?.uid;

      final results = await _searchService.searchUsers(query, excludeUserId: myUid);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _inviteUser(UserModel user) async {
    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.user?.uid;
    final ownerName = authProvider.user?.displayName ?? 'Unknown';
    final l10n = L10n.of(context)!;

    if (ownerId == null) return;

    final result = await _villageService.inviteMember(
      villageId: widget.villageId,
      ownerId: ownerId,
      ownerName: ownerName,
      inviteeId: user.id,
      inviteeName: user.characterName ?? 'Unknown',
    );

    if (!mounted) return;

    String message;
    Color color;

    switch (result) {
      case MembershipInvitationResult.success:
        message = l10n.invitationSent;
        color = Colors.greenAccent;
        widget.onInvited();
        Navigator.pop(context);
        break;
      case MembershipInvitationResult.alreadyMember:
        message = l10n.membershipAlreadyMember;
        color = Colors.orangeAccent;
        break;
      case MembershipInvitationResult.alreadyInvited:
        message = l10n.invitationAlreadySent;
        color = Colors.orangeAccent;
        break;
      case MembershipInvitationResult.villageNotFound:
        message = l10n.villageNotFound;
        color = Colors.redAccent;
        break;
      case MembershipInvitationResult.notOwner:
        message = '이장만 초대할 수 있습니다';
        color = Colors.redAccent;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 제목
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.inviteMember,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
          ),

          const SizedBox(height: 16),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? l10n.searchHint
                              : l10n.searchEmpty,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return _UserSearchTile(
                            user: user,
                            onInvite: () => _inviteUser(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 사용자 검색 결과 타일
class _UserSearchTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onInvite;

  const _UserSearchTile({
    required this.user,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.pinkAccent),
        ),
        title: Text(
          user.characterName ?? 'Unknown',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: ElevatedButton(
          onPressed: onInvite,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(l10n.inviteMember),
        ),
      ),
    );
  }
}
