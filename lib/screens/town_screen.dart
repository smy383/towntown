import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import '../providers/auth_provider.dart';
import '../main.dart' show CreateCharacterScreen, VillageLand, DrawingStroke;

class TownScreen extends StatefulWidget {
  const TownScreen({super.key});

  @override
  State<TownScreen> createState() => _TownScreenState();
}

class _TownScreenState extends State<TownScreen> {
  final VillageService _villageService = VillageService();
  List<VillageModel> _villages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVillages();
  }

  Future<void> _loadVillages() async {
    try {
      final villages = await _villageService.getAllVillages();
      if (mounted) {
        setState(() {
          _villages = villages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshVillages() async {
    await _loadVillages();
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
      );
    }
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

    if (_villages.isEmpty) {
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
        onRefresh: _refreshVillages,
        color: Colors.purpleAccent,
        backgroundColor: Colors.grey[900],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _villages.length,
          itemBuilder: (context, index) {
            return _VillageCard(
              village: _villages[index],
              onTap: () => _enterVillage(_villages[index]),
            );
          },
        ),
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final VillageModel village;
  final VoidCallback onTap;

  const _VillageCard({
    required this.village,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.3),
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
                    color: Colors.purpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: Colors.purpleAccent,
                    size: 24,
                    shadows: [
                      Shadow(
                        color: Colors.purpleAccent.withOpacity(0.6),
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
                    color: Colors.cyanAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
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
