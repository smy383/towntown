import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/village_model.dart';
import '../models/house_model.dart';

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
      if (village.visitors.contains(userId)) {
        return VillageEntryResult.alreadyInside;
      }

      // 마을이 가득 찼는지 확인
      if (village.isFull) {
        return VillageEntryResult.full;
      }

      // 비공개 마을인 경우 주민만 입장 가능
      if (!village.isPublic && !village.isMember(userId)) {
        return VillageEntryResult.private;
      }

      // 진입 처리
      final newVisitors = [...village.visitors, userId];
      transaction.update(docRef, {
        'visitors': newVisitors,
        'population': newVisitors.length,
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
      if (!village.visitors.contains(userId)) {
        return true;
      }

      // 퇴장 처리
      final newVisitors = village.visitors.where((id) => id != userId).toList();
      transaction.update(docRef, {
        'visitors': newVisitors,
        'population': newVisitors.length,
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

  // ============================================================
  // 주민 관리 메서드
  // ============================================================

  /// 주민 가입 신청
  Future<MembershipRequestResult> requestMembership({
    required String villageId,
    required String userId,
    required String userName,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) {
      return MembershipRequestResult.villageNotFound;
    }

    final village = VillageModel.fromFirestore(villageDoc);

    // 이미 주민인 경우
    if (village.isMember(userId)) {
      return MembershipRequestResult.alreadyMember;
    }

    // 이미 신청한 경우
    final existingRequest = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipRequestStatus.pending.name)
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      return MembershipRequestResult.alreadyRequested;
    }

    // 신청 생성
    final request = MembershipRequest(
      id: '',
      villageId: villageId,
      requesterId: userId,
      requesterName: userName,
      status: MembershipRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .add(request.toFirestore());

    return MembershipRequestResult.success;
  }

  /// 주민 가입 승인
  Future<bool> approveMembership({
    required String villageId,
    required String requestId,
    required String ownerId,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return false;

    final village = VillageModel.fromFirestore(villageDoc);
    if (village.ownerId != ownerId) return false; // 이장만 승인 가능

    final requestDoc = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) return false;

    final request = MembershipRequest.fromFirestore(requestDoc);

    // 트랜잭션으로 승인 처리
    await _firestore.runTransaction((transaction) async {
      // 신청 상태 업데이트
      transaction.update(requestDoc.reference, {
        'status': MembershipRequestStatus.approved.name,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 마을 멤버에 추가
      transaction.update(villageDoc.reference, {
        'members': FieldValue.arrayUnion([request.requesterId]),
      });
    });

    return true;
  }

  /// 주민 가입 거절
  Future<bool> rejectMembership({
    required String villageId,
    required String requestId,
    required String ownerId,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return false;

    final village = VillageModel.fromFirestore(villageDoc);
    if (village.ownerId != ownerId) return false; // 이장만 거절 가능

    await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .doc(requestId)
        .update({
      'status': MembershipRequestStatus.rejected.name,
      'processedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// 주민 제명
  Future<bool> removeMember({
    required String villageId,
    required String memberId,
    required String ownerId,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return false;

    final village = VillageModel.fromFirestore(villageDoc);
    if (village.ownerId != ownerId) return false; // 이장만 제명 가능
    if (memberId == ownerId) return false; // 이장은 제명 불가

    await villageDoc.reference.update({
      'members': FieldValue.arrayRemove([memberId]),
    });

    return true;
  }

  /// 주민 탈퇴 (스스로 나가기)
  Future<bool> leaveMembership({
    required String villageId,
    required String userId,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return false;

    final village = VillageModel.fromFirestore(villageDoc);
    if (village.ownerId == userId) return false; // 이장은 탈퇴 불가

    await villageDoc.reference.update({
      'members': FieldValue.arrayRemove([userId]),
    });

    return true;
  }

  /// 대기 중인 가입 신청 목록 조회
  Future<List<MembershipRequest>> getPendingRequests(String villageId) async {
    final snapshot = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .where('status', isEqualTo: MembershipRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MembershipRequest.fromFirestore(doc))
        .toList();
  }

  /// 대기 중인 가입 신청 수 스트림
  Stream<int> pendingRequestsCountStream(String villageId) {
    return _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .where('status', isEqualTo: MembershipRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 사용자의 가입 신청 상태 확인
  Future<UserMembershipStatus> getUserMembershipStatus({
    required String villageId,
    required String userId,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return UserMembershipStatus.none;

    final village = VillageModel.fromFirestore(villageDoc);

    // 이장인 경우
    if (village.ownerId == userId) {
      return UserMembershipStatus.owner;
    }

    // 주민인 경우
    if (village.members.contains(userId)) {
      return UserMembershipStatus.member;
    }

    // 신청 중인지 확인
    final pendingRequest = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('membershipRequests')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipRequestStatus.pending.name)
        .limit(1)
        .get();

    if (pendingRequest.docs.isNotEmpty) {
      return UserMembershipStatus.pending;
    }

    return UserMembershipStatus.none;
  }

  /// 주민 목록 조회 (이름 포함)
  Future<List<Map<String, String>>> getMembersList(String villageId) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) return [];

    final village = VillageModel.fromFirestore(villageDoc);
    final members = <Map<String, String>>[];

    for (final memberId in village.members) {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        members.add({
          'uid': memberId,
          'name': data['characterName'] ?? data['displayName'] ?? 'Unknown',
        });
      }
    }

    return members;
  }

  /// 내가 주민인 마을 목록 조회
  Future<List<VillageModel>> getMyMemberVillages(String userId) async {
    final snapshot = await _firestore
        .collection('villages')
        .where('members', arrayContains: userId)
        .get();

    return snapshot.docs
        .map((doc) => VillageModel.fromFirestore(doc))
        .toList();
  }

  // ============================================================
  // 주민 초대 메서드 (이장 → 사용자)
  // ============================================================

  /// 주민 초대 보내기 (이장이 사용자에게)
  Future<MembershipInvitationResult> inviteMember({
    required String villageId,
    required String ownerId,
    required String ownerName,
    required String inviteeId,
    required String inviteeName,
  }) async {
    final villageDoc = await _firestore.collection('villages').doc(villageId).get();
    if (!villageDoc.exists) {
      return MembershipInvitationResult.villageNotFound;
    }

    final village = VillageModel.fromFirestore(villageDoc);

    // 이장만 초대 가능
    if (village.ownerId != ownerId) {
      return MembershipInvitationResult.notOwner;
    }

    // 이미 주민인 경우
    if (village.isMember(inviteeId)) {
      return MembershipInvitationResult.alreadyMember;
    }

    // 이미 초대한 경우
    final existingInvitation = await _firestore
        .collection('membershipInvitations')
        .where('villageId', isEqualTo: villageId)
        .where('inviteeId', isEqualTo: inviteeId)
        .where('status', isEqualTo: MembershipInvitationStatus.pending.name)
        .limit(1)
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      return MembershipInvitationResult.alreadyInvited;
    }

    // 초대 생성
    final invitation = MembershipInvitation(
      id: '',
      villageId: villageId,
      villageName: village.name,
      inviterId: ownerId,
      inviterName: ownerName,
      inviteeId: inviteeId,
      inviteeName: inviteeName,
      status: MembershipInvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('membershipInvitations')
        .add(invitation.toFirestore());

    return MembershipInvitationResult.success;
  }

  /// 초대 수락
  Future<bool> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invitationDoc = await _firestore
        .collection('membershipInvitations')
        .doc(invitationId)
        .get();

    if (!invitationDoc.exists) return false;

    final invitation = MembershipInvitation.fromFirestore(invitationDoc);

    // 본인 초대만 수락 가능
    if (invitation.inviteeId != userId) return false;

    // 트랜잭션으로 처리
    await _firestore.runTransaction((transaction) async {
      // 초대 상태 업데이트
      transaction.update(invitationDoc.reference, {
        'status': MembershipInvitationStatus.accepted.name,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 마을 멤버에 추가
      final villageRef = _firestore.collection('villages').doc(invitation.villageId);
      transaction.update(villageRef, {
        'members': FieldValue.arrayUnion([userId]),
      });
    });

    return true;
  }

  /// 초대 거절
  Future<bool> declineInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invitationDoc = await _firestore
        .collection('membershipInvitations')
        .doc(invitationId)
        .get();

    if (!invitationDoc.exists) return false;

    final invitation = MembershipInvitation.fromFirestore(invitationDoc);

    // 본인 초대만 거절 가능
    if (invitation.inviteeId != userId) return false;

    await invitationDoc.reference.update({
      'status': MembershipInvitationStatus.declined.name,
      'processedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// 초대 취소 (이장이)
  Future<bool> cancelInvitation({
    required String invitationId,
    required String ownerId,
  }) async {
    final invitationDoc = await _firestore
        .collection('membershipInvitations')
        .doc(invitationId)
        .get();

    if (!invitationDoc.exists) return false;

    final invitation = MembershipInvitation.fromFirestore(invitationDoc);

    // 이장만 취소 가능
    if (invitation.inviterId != ownerId) return false;

    // 대기 중인 초대만 취소 가능
    if (invitation.status != MembershipInvitationStatus.pending) return false;

    await invitationDoc.reference.delete();

    return true;
  }

  /// 내게 온 초대 목록 조회
  Future<List<MembershipInvitation>> getMyInvitations(String userId) async {
    final snapshot = await _firestore
        .collection('membershipInvitations')
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipInvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MembershipInvitation.fromFirestore(doc))
        .toList();
  }

  /// 내게 온 초대 수 스트림
  Stream<int> myInvitationsCountStream(String userId) {
    return _firestore
        .collection('membershipInvitations')
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipInvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 마을에서 보낸 초대 목록 조회 (이장용)
  Future<List<MembershipInvitation>> getSentInvitations(String villageId) async {
    final snapshot = await _firestore
        .collection('membershipInvitations')
        .where('villageId', isEqualTo: villageId)
        .where('status', isEqualTo: MembershipInvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MembershipInvitation.fromFirestore(doc))
        .toList();
  }

  // ============================================================
  // 집 관리 메서드
  // ============================================================

  /// 이장 집 저장 및 마을 공개
  Future<void> saveChiefHouse({
    required String villageId,
    required HouseModel house,
  }) async {
    final villageRef = _firestore.collection('villages').doc(villageId);
    final housesRef = villageRef.collection('houses');

    await _firestore.runTransaction((transaction) async {
      // 마을 문서 가져오기
      final villageDoc = await transaction.get(villageRef);
      if (!villageDoc.exists) {
        throw Exception('마을을 찾을 수 없습니다.');
      }

      // 집 ID 생성
      final houseDocRef = housesRef.doc();
      final houseWithId = house.copyWith(id: houseDocRef.id);

      // 집 저장
      transaction.set(houseDocRef, houseWithId.toFirestore());

      // 마을 상태를 published로 변경
      transaction.update(villageRef, {
        'status': VillageStatus.published.name,
      });
    });
  }

  /// 마을의 모든 집 조회
  Future<List<HouseModel>> getHouses(String villageId) async {
    final snapshot = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('houses')
        .get();

    return snapshot.docs
        .map((doc) => HouseModel.fromFirestore(doc))
        .toList();
  }

  /// 마을의 집 스트림 (실시간 업데이트)
  Stream<List<HouseModel>> housesStream(String villageId) {
    return _firestore
        .collection('villages')
        .doc(villageId)
        .collection('houses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HouseModel.fromFirestore(doc))
            .toList());
  }

  /// 공개된 마을만 조회 (다른 사용자에게 보여줄 목록)
  /// 기존 마을(status 필드 없음)도 published로 취급
  Future<List<VillageModel>> getPublishedVillages() async {
    final snapshot = await _firestore
        .collection('villages')
        .get();

    // status가 없거나 published인 마을만 반환
    return snapshot.docs
        .map((doc) => VillageModel.fromFirestore(doc))
        .where((village) => village.isPublished)
        .toList();
  }

  /// 마을 상태 변경
  Future<void> updateVillageStatus({
    required String villageId,
    required VillageStatus status,
  }) async {
    await _firestore
        .collection('villages')
        .doc(villageId)
        .update({'status': status.name});
  }

  /// 이장의 집이 있는지 확인
  Future<bool> hasChiefHouse(String villageId) async {
    final snapshot = await _firestore
        .collection('villages')
        .doc(villageId)
        .collection('houses')
        .where('isChiefHouse', isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}

/// 마을 진입 결과
enum VillageEntryResult {
  success,      // 성공
  full,         // 정원 초과
  private,      // 비공개 마을 (주민만 입장 가능)
  notFound,     // 마을 없음
  alreadyInside, // 이미 마을 안에 있음
}

/// 주민 가입 신청 결과
enum MembershipRequestResult {
  success,         // 신청 성공
  alreadyMember,   // 이미 주민
  alreadyRequested, // 이미 신청 중
  villageNotFound, // 마을 없음
}

/// 주민 초대 결과
enum MembershipInvitationResult {
  success,         // 초대 성공
  alreadyMember,   // 이미 주민
  alreadyInvited,  // 이미 초대 중
  villageNotFound, // 마을 없음
  notOwner,        // 이장이 아님
}

/// 사용자 주민 상태
enum UserMembershipStatus {
  none,     // 일반 방문자
  pending,  // 가입 신청 중
  member,   // 주민
  owner,    // 이장 (마을 주인)
}

/// 내부 좌표 클래스
class _SectorCoord {
  final int x;
  final int y;
  _SectorCoord(this.x, this.y);
}
