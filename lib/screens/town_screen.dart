import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import '../providers/auth_provider.dart';
import '../main.dart' show CreateCharacterScreen, VillageLand, DrawingStroke;
import 'invitations_screen.dart';

class TownScreen extends StatefulWidget {
  const TownScreen({super.key});

  @override
  State<TownScreen> createState() => _TownScreenState();
}

class _TownScreenState extends State<TownScreen> {
  final VillageService _villageService = VillageService();
  List<VillageModel> _allVillages = [];
  List<VillageModel> _myMemberVillages = [];
  List<MembershipInvitation> _myInvitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    try {
      final allVillages = await _villageService.getAllVillages();
      List<VillageModel> memberVillages = [];
      List<MembershipInvitation> invitations = [];

      if (userId != null) {
        memberVillages = await _villageService.getMyMemberVillages(userId);
        invitations = await _villageService.getMyInvitations(userId);
      }

      if (mounted) {
        setState(() {
          _allVillages = allVillages;
          _myMemberVillages = memberVillages;
          _myInvitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  /// 마을 진입 처리
  Future<void> _enterVillage(VillageModel village) async {
    final authProvider = context.read<AuthProvider>();
    final l10n = L10n.of(context)!;
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    // 캐릭터 확인
    final hasCharacter = await authProvider.hasCharacter();

    if (!mounted) return;

    if (!hasCharacter) {
      // 캐릭터가 없으면 생성 화면으로
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateCharacterScreen(),
        ),
      );
      return;
    }

    // 마을 진입 시도
    final entryResult = await _villageService.enterVillage(
      villageId: village.id,
      userId: userId,
    );

    if (!mounted) return;

    // 진입 결과 처리
    switch (entryResult) {
      case VillageEntryResult.full:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.villageFull)),
        );
        return;
      case VillageEntryResult.private:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.villagePrivate)),
        );
        return;
      case VillageEntryResult.notFound:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.villageNotFound)),
        );
        return;
      case VillageEntryResult.success:
      case VillageEntryResult.alreadyInside:
        // 진입 성공 또는 이미 안에 있음 - 계속 진행
        break;
    }

    // 캐릭터 데이터 불러오기
    final userData = await authProvider.getUserData();
    if (!mounted || userData == null) return;

    final characterName = userData['characterName'] ?? '';
    final strokesData = userData['characterStrokes'] as List<dynamic>? ?? [];

    // Map 데이터를 DrawingStroke로 변환
    final characterStrokes = strokesData.map((strokeData) {
      final pointsData = strokeData['points'] as List<dynamic>? ?? [];
      final points = pointsData.map((p) => Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      )).toList();

      return DrawingStroke(
        points: points,
        color: Color(strokeData['color'] as int? ?? 0xFF000000),
        strokeWidth: (strokeData['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      );
    }).toList();

    // VillageLand로 이동
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VillageLand(
            villageId: village.id,
            characterName: characterName,
            characterStrokes: characterStrokes,
          ),
        ),
      ).then((_) => _loadData()); // 돌아오면 새로고침
    }
  }

  void _openInvitationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvitationsScreen(),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    final hasContent = _allVillages.isNotEmpty ||
                       _myMemberVillages.isNotEmpty ||
                       _myInvitations.isNotEmpty;

    if (!hasContent) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.location_city_outlined,
                  size: 48,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noVillageYet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.createFirstVillage,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.purpleAccent,
        backgroundColor: Colors.grey[900],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 받은 초대 섹션
            if (_myInvitations.isNotEmpty) ...[
              _buildSectionHeader(
                l10n.myInvitations,
                Icons.mail,
                Colors.cyanAccent,
                trailing: GestureDetector(
                  onTap: _openInvitationsScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_myInvitations.length}',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _InvitationPreviewCard(
                invitation: _myInvitations.first,
                onTap: _openInvitationsScreen,
              ),
              const SizedBox(height: 24),
            ],

            // 내가 주민인 마을 섹션
            if (_myMemberVillages.isNotEmpty) ...[
              _buildSectionHeader(
                '${l10n.membershipMember} ${l10n.townTitle}',
                Icons.home,
                Colors.greenAccent,
              ),
              const SizedBox(height: 8),
              ..._myMemberVillages.map((village) => _VillageCard(
                village: village,
                onTap: () => _enterVillage(village),
                accentColor: Colors.greenAccent,
                badge: l10n.membershipMember,
              )),
              const SizedBox(height: 24),
            ],

            // 모든 마을 섹션
            _buildSectionHeader(
              l10n.allVillages,
              Icons.public,
              Colors.purpleAccent,
            ),
            const SizedBox(height: 8),
            ..._allVillages.map((village) => _VillageCard(
              village: village,
              onTap: () => _enterVillage(village),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }
}

/// 초대 미리보기 카드
class _InvitationPreviewCard extends StatelessWidget {
  final MembershipInvitation invitation;
  final VoidCallback onTap;

  const _InvitationPreviewCard({
    required this.invitation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mail, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.villageName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invitation.inviterName}${l10n.invitationFrom('', '').split('{')[0]}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final VillageModel village;
  final VoidCallback onTap;
  final Color accentColor;
  final String? badge;

  const _VillageCard({
    required this.village,
    required this.onTap,
    this.accentColor = Colors.purpleAccent,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 마을 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: accentColor,
                    size: 24,
                    shadows: [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // 마을 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            village.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            village.sectorId,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 인구수
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${village.population}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 화살표
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
