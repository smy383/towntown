import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/village_model.dart';

class VillageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 상수
  static const int gridSize = 10000;  // 10000 x 10000 = 1억 구역
  static const int centerX = 5000;    // 중심 X 좌표
  static const int centerY = 5000;    // 중심 Y 좌표

  /// 사용자의 마을 조회
  Future<VillageModel?> getUserVillage(String userId) async {
    final query = await _firestore
        .collection('villages')
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return VillageModel.fromFirestore(query.docs.first);
  }

  /// 사용자가 마을을 가지고 있는지 확인
  Future<bool> hasVillage(String userId) async {
    final village = await getUserVillage(userId);
    return village != null;
  }

  /// 새 마을 생성
  Future<VillageModel> createVillage({
    required String userId,
    required String villageName,
  }) async {
    // 이미 마을이 있는지 확인
    if (await hasVillage(userId)) {
      throw Exception('이미 마을을 보유하고 있습니다.');
    }

    // 빈 구역 찾기
    final sector = await _findAvailableSector();

    // 마을 ID 생성
    final villageId = VillageModel.generateVillageId();

    // 마을 생성
    final village = VillageModel(
      id: villageId,
      sectorId: VillageModel.createSectorId(sector.x, sector.y),
      sectorX: sector.x,
      sectorY: sector.y,
      ownerId: userId,
      name: villageName,
      createdAt: DateTime.now(),
    );

    // Firestore에 저장
    await _firestore
        .collection('villages')
        .doc(villageId)
        .set(village.toFirestore());

    return village;
  }

  /// 빈 구역 찾기 (중심에서 가까운 곳부터)
  Future<_SectorCoord> _findAvailableSector() async {
    final random = Random();

    // 현재 마을 수에 따라 반경 결정
    final villageCount = await _getVillageCount();

    // 반경 계산: 마을이 많을수록 더 넓은 범위에서 검색
    // sqrt를 사용해서 원형으로 퍼지게
    int maxRadius = (sqrt(villageCount + 1) * 10).toInt().clamp(50, 4500);

    // 최대 100번 시도
    for (int attempt = 0; attempt < 100; attempt++) {
      // 랜덤 각도와 거리
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * maxRadius;

      // 중심에서의 좌표 계산
      int x = (centerX + distance * cos(angle)).toInt();
      int y = (centerY + distance * sin(angle)).toInt();

      // 범위 체크
      x = x.clamp(0, gridSize - 1);
      y = y.clamp(0, gridSize - 1);

      // 해당 구역이 비어있는지 확인
      final sectorId = VillageModel.createSectorId(x, y);
      final existing = await _firestore
          .collection('villages')
          .where('sectorId', isEqualTo: sectorId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return _SectorCoord(x, y);
      }
    }

    // 100번 시도 후에도 못 찾으면 에러
    throw Exception('빈 구역을 찾을 수 없습니다.');
  }

  /// 전체 마을 수 조회
  Future<int> _getVillageCount() async {
    final snapshot = await _firestore
        .collection('villages')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// 모든 마을 위치 조회 (지구본 표시용)
  Future<List<VillageModel>> getAllVillages() async {
    final snapshot = await _firestore
        .collection('villages')
        .get();

    return snapshot.docs
        .map((doc) => VillageModel.fromFirestore(doc))
        .toList();
  }

  /// 마을 위치만 조회 (경량 버전)
  Future<List<Map<String, int>>> getAllVillagePositions() async {
    final snapshot = await _firestore
        .collection('villages')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'x': data['sectorX'] as int,
        'y': data['sectorY'] as int,
      };
    }).toList();
  }

  /// 마을 삭제
  Future<void> deleteVillage(String villageId) async {
    await _firestore
        .collection('villages')
        .doc(villageId)
        .delete();
  }

  /// 마을 정보 업데이트
  Future<void> updateVillage(String villageId, Map<String, dynamic> data) async {
    await _firestore
        .collection('villages')
        .doc(villageId)
        .update(data);
  }
}

/// 내부 좌표 클래스
class _SectorCoord {
  final int x;
  final int y;
  _SectorCoord(this.x, this.y);
}
