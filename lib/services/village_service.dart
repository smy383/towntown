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

  /// 마을 진입
  /// 성공 시 true, 실패 시 false 반환
  Future<VillageEntryResult> enterVillage({
    required String villageId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('villages').doc(villageId);

    return await _firestore.runTransaction<VillageEntryResult>((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        return VillageEntryResult.notFound;
      }

      final village = VillageModel.fromFirestore(doc);

      // 이미 마을에 있는지 확인
      if (village.residents.contains(userId)) {
        return VillageEntryResult.alreadyInside;
      }

      // 마을이 가득 찼는지 확인
      if (village.isFull) {
        return VillageEntryResult.full;
      }

      // 비공개 마을인 경우 (추후 초대 시스템 구현)
      if (!village.isPublic && village.ownerId != userId) {
        return VillageEntryResult.private;
      }

      // 진입 처리
      final newResidents = [...village.residents, userId];
      transaction.update(docRef, {
        'residents': newResidents,
        'population': newResidents.length,
      });

      return VillageEntryResult.success;
    });
  }

  /// 마을 퇴장
  Future<bool> leaveVillage({
    required String villageId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('villages').doc(villageId);

    return await _firestore.runTransaction<bool>((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        return false;
      }

      final village = VillageModel.fromFirestore(doc);

      // 마을에 없으면 무시
      if (!village.residents.contains(userId)) {
        return true;
      }

      // 퇴장 처리
      final newResidents = village.residents.where((id) => id != userId).toList();
      transaction.update(docRef, {
        'residents': newResidents,
        'population': newResidents.length,
      });

      return true;
    });
  }

  /// 마을 조회 (ID로)
  Future<VillageModel?> getVillage(String villageId) async {
    final doc = await _firestore.collection('villages').doc(villageId).get();
    if (!doc.exists) return null;
    return VillageModel.fromFirestore(doc);
  }
}

/// 마을 진입 결과
enum VillageEntryResult {
  success,      // 성공
  full,         // 정원 초과
  private,      // 비공개 마을 (초대 필요)
  notFound,     // 마을 없음
  alreadyInside, // 이미 마을 안에 있음
}

/// 내부 좌표 클래스
class _SectorCoord {
  final int x;
  final int y;
  _SectorCoord(this.x, this.y);
}
