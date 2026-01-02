import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import 'create_village_screen.dart';
import 'village_map_screen.dart';
import '../main.dart' show CreateCharacterScreen, VillageLand, DrawingStroke;

class MyVillageScreen extends StatefulWidget {
  const MyVillageScreen({super.key});

  @override
  State<MyVillageScreen> createState() => _MyVillageScreenState();
}

class _MyVillageScreenState extends State<MyVillageScreen> {
  final VillageService _villageService = VillageService();
  VillageModel? _myVillage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyVillage();
  }

  Future<void> _loadMyVillage() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final village = await _villageService.getUserVillage(userId);
        if (mounted) {
          setState(() {
            _myVillage = village;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// 마을 진입 처리
  Future<void> _enterMyVillage() async {
    if (_myVillage == null) return;

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

    // 이장인 경우 집 확인
    if (_myVillage!.ownerId == userId) {
      final hasChiefHouse = await _villageService.hasChiefHouse(_myVillage!.id);
      if (!mounted) return;

      if (!hasChiefHouse) {
        // 이장 집이 없으면 집 짓기 화면으로
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VillageMapScreen(village: _myVillage!),
          ),
        );
        return;
      }
    }

    // 마을 진입 시도
    final entryResult = await _villageService.enterVillage(
      villageId: _myVillage!.id,
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
            villageId: _myVillage!.id,
            villageName: _myVillage!.name,
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.myVillage,
          style: TextStyle(
            color: Colors.purpleAccent[100],
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.purpleAccent.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : _myVillage != null
              ? _buildMyVillageView(l10n)
              : _buildEmptyView(l10n),
    );
  }

  Widget _buildMyVillageView(L10n l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 내 마을 카드
          _MyVillageCard(village: _myVillage!),

          const SizedBox(height: 24),

          // 마을 정보 섹션
          Text(
            l10n.villageLocation,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purpleAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _myVillage!.sectorId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 마을 입장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enterMyVillage,
              icon: const Icon(Icons.login),
              label: Text(l10n.myVillage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 다른 마을 탐험 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoon)),
                );
              },
              icon: const Icon(Icons.explore),
              label: Text(l10n.exploreVillage),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(L10n l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              l10n.townEmpty,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.townEmptyDesc,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateVillageScreen(),
                  ),
                );
                if (result == true) {
                  _loadMyVillage();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.createVillage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyVillageCard extends StatelessWidget {
  final VillageModel village;

  const _MyVillageCard({required this.village});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purpleAccent.withOpacity(0.2),
            Colors.cyanAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  Icons.location_city,
                  color: Colors.purpleAccent,
                  size: 30,
                  shadows: [
                    Shadow(
                      color: Colors.purpleAccent.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      village.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.purpleAccent.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${village.id}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.people,
                label: '${village.population}',
                color: Colors.cyanAccent,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.calendar_today,
                label: _formatDate(village.createdAt),
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
