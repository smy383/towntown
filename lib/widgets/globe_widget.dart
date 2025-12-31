import 'dart:math';
import 'package:flutter/material.dart';

/// 마을 위치 데이터
class VillagePoint {
  final int x;
  final int y;
  final bool isHighlighted;

  VillagePoint({
    required this.x,
    required this.y,
    this.isHighlighted = false,
  });

  /// 해당 위치를 화면 정면에 보이게 하는 회전값 계산
  double get targetRotationY {
    // x좌표를 경도로 변환 (0~9999 → -π ~ π)
    // 정면에 보이려면 해당 경도의 반대 방향으로 회전
    return -((x / 10000) * 2 * pi - pi);
  }

  double get targetRotationX {
    // y좌표를 위도로 변환 (0~9999 → -π/2 ~ π/2)
    // 정면에 보이려면 해당 위도만큼 기울임
    return -((y / 10000) * pi - pi / 2);
  }
}

/// 지구본 위젯
class GlobeWidget extends StatefulWidget {
  final List<VillagePoint> villages;
  final VillagePoint? newVillage;
  final double? targetRotationX;  // 목표 수직 회전 (외부 제어용)
  final double? targetRotationY;  // 목표 수평 회전 (외부 제어용)
  final bool autoRotate;
  final bool enableGesture;  // 제스처 활성화 여부
  final Color globeColor;
  final Color dotColor;
  final Color highlightColor;

  const GlobeWidget({
    super.key,
    this.villages = const [],
    this.newVillage,
    this.targetRotationX,
    this.targetRotationY,
    this.autoRotate = true,
    this.enableGesture = true,
    this.globeColor = Colors.cyanAccent,
    this.dotColor = Colors.cyanAccent,
    this.highlightColor = Colors.yellowAccent,
  });

  @override
  State<GlobeWidget> createState() => _GlobeWidgetState();
}

class _GlobeWidgetState extends State<GlobeWidget>
    with TickerProviderStateMixin {
  late AnimationController _autoRotateController;
  AnimationController? _targetRotationController;
  double _rotationY = 0;
  double _rotationX = 0;
  double _baseRotationY = 0;  // 자동 회전 시작점

  @override
  void initState() {
    super.initState();

    // 자동 회전 컨트롤러
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    if (widget.autoRotate) {
      _autoRotateController.repeat();
    }

    _autoRotateController.addListener(_onAutoRotate);

    // 초기 목표 회전값이 있으면 설정
    if (widget.targetRotationX != null) {
      _rotationX = widget.targetRotationX!;
    }
    if (widget.targetRotationY != null) {
      _rotationY = widget.targetRotationY!;
      _baseRotationY = widget.targetRotationY!;
    }
  }

  void _onAutoRotate() {
    if (mounted && widget.autoRotate) {
      setState(() {
        _rotationY = _baseRotationY + _autoRotateController.value * 2 * pi;
      });
    }
  }

  @override
  void didUpdateWidget(GlobeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // autoRotate 상태 변경
    if (widget.autoRotate != oldWidget.autoRotate) {
      if (widget.autoRotate) {
        _baseRotationY = _rotationY;
        _autoRotateController.repeat();
      } else {
        _autoRotateController.stop();
      }
    }

    // 목표 회전값이 변경되면 애니메이션
    if (widget.targetRotationX != oldWidget.targetRotationX ||
        widget.targetRotationY != oldWidget.targetRotationY) {
      _animateToTarget();
    }
  }

  void _animateToTarget() {
    if (widget.targetRotationX == null && widget.targetRotationY == null) {
      return;
    }

    _targetRotationController?.dispose();
    _targetRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final startX = _rotationX;
    final startY = _rotationY;
    final endX = widget.targetRotationX ?? _rotationX;
    final endY = widget.targetRotationY ?? _rotationY;

    _targetRotationController!.addListener(() {
      if (mounted) {
        final t = Curves.easeInOutCubic.transform(_targetRotationController!.value);
        setState(() {
          _rotationX = startX + (endX - startX) * t;
          _rotationY = startY + (endY - startY) * t;
        });
      }
    });

    _targetRotationController!.forward();
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    _targetRotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.enableGesture
          ? (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX += details.delta.dy * 0.01;
                _rotationX = _rotationX.clamp(-pi / 2, pi / 2);
                _baseRotationY = _rotationY;
              });
            }
          : null,
      child: CustomPaint(
        painter: GlobePainter(
          villages: widget.villages,
          newVillage: widget.newVillage,
          rotationX: _rotationX,
          rotationY: _rotationY,
          globeColor: widget.globeColor,
          dotColor: widget.dotColor,
          highlightColor: widget.highlightColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// 지구본 CustomPainter
class GlobePainter extends CustomPainter {
  final List<VillagePoint> villages;
  final VillagePoint? newVillage;
  final double rotationX;
  final double rotationY;
  final Color globeColor;
  final Color dotColor;
  final Color highlightColor;

  static const int gridSize = 10000;

  GlobePainter({
    required this.villages,
    this.newVillage,
    required this.rotationX,
    required this.rotationY,
    required this.globeColor,
    required this.dotColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    // 지구본 배경 (어두운 구체)
    final bgPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 지구본 테두리 (네온 글로우)
    for (double blur = 20; blur >= 5; blur -= 5) {
      final glowPaint = Paint()
        ..color = globeColor.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = blur
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawCircle(center, radius, glowPaint);
    }

    final borderPaint = Paint()
      ..color = globeColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // 위도선 그리기
    _drawLatitudeLines(canvas, center, radius);

    // 경도선 그리기
    _drawLongitudeLines(canvas, center, radius);

    // 마을 점들 그리기
    for (final village in villages) {
      _drawVillagePoint(canvas, center, radius, village, false);
    }

    // 새 마을 강조 표시
    if (newVillage != null) {
      _drawVillagePoint(canvas, center, radius, newVillage!, true);
    }
  }

  /// 위도선 그리기
  void _drawLatitudeLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = globeColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 5개의 위도선
    for (int i = -2; i <= 2; i++) {
      final lat = i * (pi / 6);  // -60° ~ +60°
      final y = center.dy - radius * sin(lat) * cos(rotationX);
      final lineRadius = radius * cos(lat);

      if (lineRadius > 0) {
        final rect = Rect.fromCenter(
          center: Offset(center.dx, y),
          width: lineRadius * 2,
          height: lineRadius * 2 * sin(rotationX).abs().clamp(0.1, 1.0),
        );

        canvas.drawOval(rect, linePaint);
      }
    }
  }

  /// 경도선 그리기
  void _drawLongitudeLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = globeColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 8개의 경도선
    for (int i = 0; i < 8; i++) {
      final lng = i * (pi / 4) + rotationY;
      final path = Path();

      bool started = false;
      for (double lat = -pi / 2; lat <= pi / 2; lat += 0.1) {
        final point = _projectPoint(lat, lng, center, radius);
        if (point != null) {
          if (!started) {
            path.moveTo(point.dx, point.dy);
            started = true;
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
      }

      canvas.drawPath(path, linePaint);
    }
  }

  /// 마을 점 그리기
  void _drawVillagePoint(
    Canvas canvas,
    Offset center,
    double radius,
    VillagePoint village,
    bool isNew,
  ) {
    // 구역 좌표를 위도/경도로 변환
    final lng = (village.x / gridSize) * 2 * pi - pi + rotationY;
    final lat = (village.y / gridSize) * pi - pi / 2;

    final point = _projectPoint(lat, lng, center, radius);
    if (point == null) return;  // 뒷면이면 그리지 않음

    final depth = _getDepth(lat, lng);
    final dotRadius = isNew ? 6.0 : 3.0;
    final opacity = (depth * 0.7 + 0.3).clamp(0.3, 1.0);

    final color = isNew ? highlightColor : dotColor;

    // 글로우 효과
    if (isNew || village.isHighlighted) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.5 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(point, dotRadius * 2, glowPaint);
    }

    // 점
    final dotPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, dotRadius, dotPaint);
  }

  /// 3D 좌표를 2D 화면 좌표로 투영
  Offset? _projectPoint(double lat, double lng, Offset center, double radius) {
    // 3D 좌표 계산
    final x = cos(lat) * sin(lng);
    final y = sin(lat) * cos(rotationX) - cos(lat) * cos(lng) * sin(rotationX);
    final z = sin(lat) * sin(rotationX) + cos(lat) * cos(lng) * cos(rotationX);

    // 뒷면 체크 (z < 0이면 뒷면)
    if (z < -0.1) return null;

    return Offset(
      center.dx + x * radius,
      center.dy - y * radius,
    );
  }

  /// 깊이 값 계산 (앞면: 1, 뒷면: 0)
  double _getDepth(double lat, double lng) {
    final z = sin(lat) * sin(rotationX) + cos(lat) * cos(lng) * cos(rotationX);
    return (z + 1) / 2;  // -1~1 → 0~1
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.villages != villages ||
        oldDelegate.newVillage != newVillage;
  }
}
