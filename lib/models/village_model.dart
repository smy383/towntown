import 'package:cloud_firestore/cloud_firestore.dart';

/// 구역 타입
enum SectorType {
  available,   // 정착 가능
  occupied,    // 마을 있음
  ocean,       // 바다
  unexplored,  // 미개척
  special,     // 특수 구역
  reserved,    // 시스템 예약
}

/// 마을 모델
class VillageModel {
  final String id;           // 마을 고유 ID (예: "NT-7X2K9M")
  final String sectorId;     // 구역 좌표 (예: "5847-3291")
  final int sectorX;         // X 좌표 (0-9999)
  final int sectorY;         // Y 좌표 (0-9999)
  final String ownerId;      // 소유자 UID (이장)
  final String name;         // 마을 이름
  final DateTime createdAt;  // 생성일
  final int population;      // 현재 접속 인원
  final bool isPublic;       // 공개 여부 (true: 공개, false: 비공개)
  final List<String> visitors;  // 현재 마을에 접속 중인 사용자 UID 목록
  final List<String> members;   // 주민 UID 목록 (이장 승인 받은 사람들)
  final String? description; // 마을 설명

  VillageModel({
    required this.id,
    required this.sectorId,
    required this.sectorX,
    required this.sectorY,
    required this.ownerId,
    required this.name,
    required this.createdAt,
    this.population = 0,
    this.isPublic = true,
    this.visitors = const [],
    this.members = const [],
    this.description,
  });

  /// 기본 수용 인원
  static const int baseCapacity = 10;

  /// 주민 1명당 추가 수용 인원
  static const int capacityPerMember = 5;

  /// 최대 수용 인원 (기본 10명 + 주민 수 * 5명)
  int get maxPopulation => baseCapacity + (members.length * capacityPerMember);

  /// 마을에 입장 가능한지 확인
  bool get canEnter => population < maxPopulation;

  /// 마을이 가득 찼는지 확인
  bool get isFull => population >= maxPopulation;

  /// 주민 수
  int get memberCount => members.length;

  /// 특정 사용자가 주민인지 확인
  bool isMember(String uid) => members.contains(uid) || uid == ownerId;

  /// 특정 사용자가 이장인지 확인
  bool isOwner(String uid) => uid == ownerId;

  /// 특정 사용자가 입장 가능한지 확인 (비공개 마을은 주민만)
  bool canUserEnter(String uid) {
    if (!canEnter) return false;  // 정원 초과
    if (isPublic) return true;    // 공개 마을은 누구나
    return isMember(uid);         // 비공개 마을은 주민만
  }

  /// 구역 ID 생성 (좌표 → "XXXX-YYYY")
  static String createSectorId(int x, int y) {
    return '${x.toString().padLeft(4, '0')}-${y.toString().padLeft(4, '0')}';
  }

  /// 마을 ID 생성 (랜덤 6자리)
  static String generateVillageId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외
    final random = DateTime.now().millisecondsSinceEpoch;
    String id = 'NT-';
    for (int i = 0; i < 6; i++) {
      id += chars[(random ~/ (i + 1) * 17) % chars.length];
    }
    return id;
  }

  factory VillageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VillageModel(
      id: doc.id,
      sectorId: data['sectorId'] ?? '',
      sectorX: data['sectorX'] ?? 0,
      sectorY: data['sectorY'] ?? 0,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      population: data['population'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      // 기존 residents 필드도 visitors로 읽기 (하위 호환성)
      visitors: List<String>.from(data['visitors'] ?? data['residents'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sectorId': sectorId,
      'sectorX': sectorX,
      'sectorY': sectorY,
      'ownerId': ownerId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'population': population,
      'isPublic': isPublic,
      'visitors': visitors,
      'members': members,
      'description': description,
    };
  }

  VillageModel copyWith({
    String? id,
    String? sectorId,
    int? sectorX,
    int? sectorY,
    String? ownerId,
    String? name,
    DateTime? createdAt,
    int? population,
    bool? isPublic,
    List<String>? visitors,
    List<String>? members,
    String? description,
  }) {
    return VillageModel(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      sectorX: sectorX ?? this.sectorX,
      sectorY: sectorY ?? this.sectorY,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      population: population ?? this.population,
      isPublic: isPublic ?? this.isPublic,
      visitors: visitors ?? this.visitors,
      members: members ?? this.members,
      description: description ?? this.description,
    );
  }
}

/// 주민 가입 신청 상태
enum MembershipRequestStatus {
  pending,   // 대기 중
  approved,  // 승인됨
  rejected,  // 거절됨
}

/// 주민 가입 신청 모델
class MembershipRequest {
  final String id;
  final String villageId;
  final String requesterId;
  final String requesterName;
  final MembershipRequestStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  MembershipRequest({
    required this.id,
    required this.villageId,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory MembershipRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipRequest(
      id: doc.id,
      villageId: data['villageId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      status: MembershipRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MembershipRequestStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'villageId': villageId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
    };
  }
}

/// 주민 초대 상태
enum MembershipInvitationStatus {
  pending,   // 대기 중
  accepted,  // 수락됨
  declined,  // 거절됨
}

/// 주민 초대 모델 (이장이 사용자에게 보내는 초대)
class MembershipInvitation {
  final String id;
  final String villageId;
  final String villageName;
  final String inviterId;      // 이장 UID
  final String inviterName;    // 이장 이름
  final String inviteeId;      // 초대받는 사용자 UID
  final String inviteeName;    // 초대받는 사용자 이름
  final MembershipInvitationStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  MembershipInvitation({
    required this.id,
    required this.villageId,
    required this.villageName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    required this.inviteeName,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory MembershipInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipInvitation(
      id: doc.id,
      villageId: data['villageId'] ?? '',
      villageName: data['villageName'] ?? '',
      inviterId: data['inviterId'] ?? '',
      inviterName: data['inviterName'] ?? '',
      inviteeId: data['inviteeId'] ?? '',
      inviteeName: data['inviteeName'] ?? '',
      status: MembershipInvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MembershipInvitationStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'villageId': villageId,
      'villageName': villageName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
    };
  }
}
