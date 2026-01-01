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
  final String ownerId;      // 소유자 UID
  final String name;         // 마을 이름
  final DateTime createdAt;  // 생성일
  final int population;      // 현재 인구 수
  final int maxPopulation;   // 최대 수용 인원 (기본 10명)
  final bool isPublic;       // 공개 여부 (true: 공개, false: 비공개)
  final List<String> residents; // 현재 마을에 있는 사용자 UID 목록
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
    this.maxPopulation = 10,
    this.isPublic = true,
    this.residents = const [],
    this.description,
  });

  /// 마을에 입장 가능한지 확인
  bool get canEnter => population < maxPopulation;

  /// 마을이 가득 찼는지 확인
  bool get isFull => population >= maxPopulation;

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
      maxPopulation: data['maxPopulation'] ?? 10,
      isPublic: data['isPublic'] ?? true,
      residents: List<String>.from(data['residents'] ?? []),
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
      'maxPopulation': maxPopulation,
      'isPublic': isPublic,
      'residents': residents,
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
    int? maxPopulation,
    bool? isPublic,
    List<String>? residents,
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
      maxPopulation: maxPopulation ?? this.maxPopulation,
      isPublic: isPublic ?? this.isPublic,
      residents: residents ?? this.residents,
      description: description ?? this.description,
    );
  }
}
