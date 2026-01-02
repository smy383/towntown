import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 그리기 스트로크 (캐릭터와 공유)
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 3.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    final pointsData = map['points'] as List<dynamic>? ?? [];
    final points = pointsData.map((p) => Offset(
      (p['x'] as num).toDouble(),
      (p['y'] as num).toDouble(),
    )).toList();

    return DrawingStroke(
      points: points,
      color: Color(map['color'] as int? ?? 0xFF000000),
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

/// 집 모델
class HouseModel {
  final String id;
  final String ownerId;       // 집 주인 UID
  final String ownerName;     // 집 주인 이름
  final double x;             // 월드 X 좌표
  final double y;             // 월드 Y 좌표
  final double width;         // 집 너비 (기본 150)
  final double height;        // 집 높이 (기본 120)
  final double doorX;         // 문 X 위치 (상대 좌표, 0-1)
  final double doorY;         // 문 Y 위치 (상대 좌표, 0-1)
  final double doorWidth;     // 문 너비
  final double doorHeight;    // 문 높이
  final List<DrawingStroke> strokes;  // 그림 데이터
  final bool isChiefHouse;    // 이장의 집 여부
  final DateTime createdAt;

  HouseModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.x,
    required this.y,
    this.width = 300,
    this.height = 240,
    this.doorX = 0.5,         // 기본: 하단 중앙
    this.doorY = 1.0,         // 기본: 하단
    this.doorWidth = 60,
    this.doorHeight = 80,
    required this.strokes,
    this.isChiefHouse = false,
    required this.createdAt,
  });

  /// 캔버스 크기 (그리기용, 2배 확대)
  static const double canvasWidth = 300;
  static const double canvasHeight = 240;

  /// 렌더링 크기 (월드에서 표시되는 크기)
  static const double renderWidth = 300;
  static const double renderHeight = 240;

  /// 문 가이드 크기 (캔버스 기준)
  static const double doorGuideWidth = 60;
  static const double doorGuideHeight = 80;

  /// 문의 월드 좌표
  Offset get doorWorldPosition {
    return Offset(
      x + (doorX * width) - (doorWidth / 2),
      y + (doorY * height) - doorHeight,
    );
  }

  factory HouseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final strokesData = data['strokes'] as List<dynamic>? ?? [];
    final strokes = strokesData
        .map((s) => DrawingStroke.fromMap(s as Map<String, dynamic>))
        .toList();

    return HouseModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,
      width: (data['width'] as num?)?.toDouble() ?? 300,
      height: (data['height'] as num?)?.toDouble() ?? 240,
      doorX: (data['doorX'] as num?)?.toDouble() ?? 0.5,
      doorY: (data['doorY'] as num?)?.toDouble() ?? 1.0,
      doorWidth: (data['doorWidth'] as num?)?.toDouble() ?? 60,
      doorHeight: (data['doorHeight'] as num?)?.toDouble() ?? 80,
      strokes: strokes,
      isChiefHouse: data['isChiefHouse'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'doorX': doorX,
      'doorY': doorY,
      'doorWidth': doorWidth,
      'doorHeight': doorHeight,
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'isChiefHouse': isChiefHouse,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  HouseModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    double? x,
    double? y,
    double? width,
    double? height,
    double? doorX,
    double? doorY,
    double? doorWidth,
    double? doorHeight,
    List<DrawingStroke>? strokes,
    bool? isChiefHouse,
    DateTime? createdAt,
  }) {
    return HouseModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      doorX: doorX ?? this.doorX,
      doorY: doorY ?? this.doorY,
      doorWidth: doorWidth ?? this.doorWidth,
      doorHeight: doorHeight ?? this.doorHeight,
      strokes: strokes ?? this.strokes,
      isChiefHouse: isChiefHouse ?? this.isChiefHouse,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
