import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import '../providers/auth_provider.dart';
import '../screens/membership_management_screen.dart';

/// 마을 화면에 표시되는 주민 상태/신청 버튼
class MembershipButton extends StatefulWidget {
  final String villageId;
  final VoidCallback? onStatusChanged;

  const MembershipButton({
    super.key,
    required this.villageId,
    this.onStatusChanged,
  });

  @override
  State<MembershipButton> createState() => _MembershipButtonState();
}

class _MembershipButtonState extends State<MembershipButton> {
  final VillageService _villageService = VillageService();
  UserMembershipStatus _status = UserMembershipStatus.none;
  VillageModel? _village;
  int _pendingRequestsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    try {
      final status = await _villageService.getUserMembershipStatus(
        villageId: widget.villageId,
        userId: userId,
      );
      final village = await _villageService.getVillage(widget.villageId);

      // 이장인 경우 대기 중인 신청 수 가져오기
      int pendingCount = 0;
      if (status == UserMembershipStatus.owner) {
        final requests = await _villageService.getPendingRequests(widget.villageId);
        pendingCount = requests.length;
      }

      if (mounted) {
        setState(() {
          _status = status;
          _village = village;
          _pendingRequestsCount = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestMembership() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    final userName = authProvider.user?.displayName ?? 'Unknown';
    final l10n = L10n.of(context)!;

    if (userId == null) return;

    final result = await _villageService.requestMembership(
      villageId: widget.villageId,
      userId: userId,
      userName: userName,
    );

    if (!mounted) return;

    String message;
    Color color;

    switch (result) {
      case MembershipRequestResult.success:
        message = l10n.membershipRequestSent;
        color = Colors.greenAccent;
        _loadStatus(); // 상태 새로고침
        break;
      case MembershipRequestResult.alreadyMember:
        message = l10n.membershipAlreadyMember;
        color = Colors.orangeAccent;
        break;
      case MembershipRequestResult.alreadyRequested:
        message = l10n.membershipAlreadyRequested;
        color = Colors.orangeAccent;
        break;
      case MembershipRequestResult.villageNotFound:
        message = l10n.villageNotFound;
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

  Future<void> _leaveMembership() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    final l10n = L10n.of(context)!;

    if (userId == null) return;

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.membershipLeave, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.membershipLeaveConfirm, style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leave, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _villageService.leaveMembership(
      villageId: widget.villageId,
      userId: userId,
    );

    if (success && mounted) {
      _loadStatus();
      widget.onStatusChanged?.call();
    }
  }

  void _openManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipManagementScreen(
          villageId: widget.villageId,
          villageName: _village?.name ?? '',
        ),
      ),
    ).then((_) {
      if (mounted) _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    if (_isLoading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
        ),
      );
    }

    switch (_status) {
      case UserMembershipStatus.owner:
        return _buildOwnerButton(l10n);
      case UserMembershipStatus.member:
        return _buildMemberButton(l10n);
      case UserMembershipStatus.pending:
        return _buildPendingButton(l10n);
      case UserMembershipStatus.none:
        return _buildRequestButton(l10n);
    }
  }

  /// 이장 버튼 (관리 화면으로 이동)
  Widget _buildOwnerButton(L10n l10n) {
    return GestureDetector(
      onTap: _openManagementScreen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              l10n.membershipOwner,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_pendingRequestsCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_pendingRequestsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 주민 버튼
  Widget _buildMemberButton(L10n l10n) {
    return GestureDetector(
      onTap: _leaveMembership,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              l10n.membershipMember,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 신청 중 버튼
  Widget _buildPendingButton(L10n l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 4),
          Text(
            l10n.membershipPending,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 주민 신청 버튼
  Widget _buildRequestButton(L10n l10n) {
    return GestureDetector(
      onTap: _requestMembership,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add, color: Colors.cyanAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              l10n.membershipRequest,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
