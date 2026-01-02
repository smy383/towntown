import 'dart:math';
import 'package:flutter/material.dart';
import '../models/house_model.dart';
import '../main.dart' as main_app;

/// 집 내부 화면
class HouseInteriorScreen extends StatefulWidget {
  final HouseModel house;
  final String visitorName;
  final List<main_app.DrawingStroke> visitorStrokes;

  const HouseInteriorScreen({
    super.key,
    required this.house,
    required this.visitorName,
    required this.visitorStrokes,
  });

  @override
  State<HouseInteriorScreen> createState() => _HouseInteriorScreenState();
}

class _HouseInteriorScreenState extends State<HouseInteriorScreen>
    with TickerProviderStateMixin {
  // 내부 공간 크기 (2배 확대)
  static const double roomWidth = 1200;
  static const double roomHeight = 1000;

  // 캐릭터 위치 (방 중앙에서 시작)
  double _charX = roomWidth / 2;
  double _charY = roomHeight / 2;

  // 이동 관련
  bool _isMoving = false;
  bool _facingRight = true;
  double _targetX = 0;
  double _targetY = 0;

  // 애니메이션
  late AnimationController _walkController;
  AnimationController? _moveController;
  Animation<double>? _moveAnimation;

  // 문 영역 (하단 중앙) - 2배 확대
  static const double doorWidth = 160;
  static const double doorHeight = 200;
  static const double doorX = (roomWidth - doorWidth) / 2;
  static const double doorY = roomHeight - doorHeight;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _walkController.dispose();
    _moveController?.dispose();
    super.dispose();
  }

  void _moveCharacter(Offset target) {
    // 경계 내로 제한 (상단 벽 160 이하로는 이동 불가)
    final targetX = target.dx.clamp(60.0, roomWidth - 60.0);
    final targetY = target.dy.clamp(180.0, roomHeight - 100.0);

    // 현재 위치와 같으면 이동하지 않음
    if ((targetX - _charX).abs() < 1 && (targetY - _charY).abs() < 1) {
      return;
    }

    setState(() {
      _isMoving = true;
      _facingRight = targetX > _charX;
      _targetX = targetX;
      _targetY = targetY;
    });

    final startX = _charX;
    final startY = _charY;

    final distance = sqrt(
      pow(_targetX - startX, 2) + pow(_targetY - startY, 2),
    );

    final duration = Duration(milliseconds: (distance / 180 * 1000).toInt());

    _moveController?.dispose();
    _moveController = AnimationController(duration: duration, vsync: this);

    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moveController!, curve: Curves.linear),
    );

    _moveAnimation!.addListener(() {
      setState(() {
        final progress = _moveAnimation!.value;
        _charX = startX + (_targetX - startX) * progress;
        _charY = startY + (_targetY - startY) * progress;
      });
    });

    _moveAnimation!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isMoving = false);
        _walkController.stop();
        _walkController.reset();

        // 문 영역에 도착하면 나가기 확인
        if (_isAtDoor()) {
          _showExitDialog();
        }
      }
    });

    _walkController.duration = const Duration(milliseconds: 500);
    _walkController.repeat();
    _moveController!.forward();
  }

  bool _isAtDoor() {
    return _charX >= doorX &&
        _charX <= doorX + doorWidth &&
        _charY >= doorY - 20;
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '나가기',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '집에서 나가시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 집에서 나가기
            },
            child: const Text(
              '나가기',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            _buildTopBar(),

            // 방 내부 (캐릭터 중심 이동)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewWidth = constraints.maxWidth;
                  final viewHeight = constraints.maxHeight;

                  return AnimatedBuilder(
                    animation: _walkController,
                    builder: (context, child) {
                      // 캐릭터를 화면 중앙에 두기 위한 오프셋 (클램핑 적용)
                      double offsetX = viewWidth / 2 - _charX;
                      double offsetY = viewHeight / 2 - _charY;

                      // 카메라가 방 경계를 벗어나지 않도록 클램핑
                      final maxOffsetX = 0.0;
                      final minOffsetX = viewWidth - roomWidth;
                      final maxOffsetY = 0.0;
                      final minOffsetY = viewHeight - roomHeight;

                      offsetX = offsetX.clamp(minOffsetX, maxOffsetX);
                      offsetY = offsetY.clamp(minOffsetY, maxOffsetY);

                      // 캐릭터의 화면상 위치 계산
                      final charScreenX = _charX + offsetX;
                      final charScreenY = _charY + offsetY;

                      return GestureDetector(
                        onTapDown: (details) {
                          // 탭 위치를 월드 좌표로 변환
                          final worldX = details.localPosition.dx - offsetX;
                          final worldY = details.localPosition.dy - offsetY;
                          _moveCharacter(Offset(worldX, worldY));
                        },
                        child: CustomPaint(
                          size: Size(viewWidth, viewHeight),
                          painter: _RoomViewPainter(
                            offsetX: offsetX,
                            offsetY: offsetY,
                            roomWidth: roomWidth,
                            roomHeight: roomHeight,
                            doorX: doorX,
                            doorY: doorY,
                            doorWidth: doorWidth,
                            doorHeight: doorHeight,
                            charX: charScreenX,
                            charY: charScreenY,
                            visitorStrokes: widget.visitorStrokes,
                            isMoving: _isMoving,
                            animationValue: _walkController.value,
                            facingRight: _facingRight,
                            ownerName: widget.house.ownerName,
                            isChiefHouse: widget.house.isChiefHouse,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            widget.house.ownerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // 균형을 위한 공간
        ],
      ),
    );
  }

}

/// 방 전체 뷰 페인터 (캐릭터 중심 이동, 모바일 호환)
class _RoomViewPainter extends CustomPainter {
  final double offsetX;
  final double offsetY;
  final double roomWidth;
  final double roomHeight;
  final double doorX;
  final double doorY;
  final double doorWidth;
  final double doorHeight;
  final double charX;
  final double charY;
  final List<main_app.DrawingStroke> visitorStrokes;
  final bool isMoving;
  final double animationValue;
  final bool facingRight;
  final String ownerName;
  final bool isChiefHouse;

  _RoomViewPainter({
    required this.offsetX,
    required this.offsetY,
    required this.roomWidth,
    required this.roomHeight,
    required this.doorX,
    required this.doorY,
    required this.doorWidth,
    required this.doorHeight,
    required this.charX,
    required this.charY,
    required this.visitorStrokes,
    required this.isMoving,
    required this.animationValue,
    required this.facingRight,
    required this.ownerName,
    required this.isChiefHouse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 방 오프셋 적용
    canvas.translate(offsetX, offsetY);

    // 바닥 타일
    final tilePaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, roomWidth, roomHeight), tilePaint);

    final linePaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1;

    const tileSize = 100.0;
    for (double x = 0; x <= roomWidth; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, roomHeight), linePaint);
    }
    for (double y = 0; y <= roomHeight; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(roomWidth, y), linePaint);
    }

    // 벽 (상단)
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.grey[900]!, Colors.grey[850]!],
      ).createShader(Rect.fromLTWH(0, 0, roomWidth, 160));
    canvas.drawRect(Rect.fromLTWH(0, 0, roomWidth, 160), wallPaint);

    // 벽 하단 라인
    final wallLinePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(0, 160), Offset(roomWidth, 160), wallLinePaint);

    // 문
    _drawDoor(canvas);

    // 집 주인 표시
    _drawOwnerLabel(canvas);

    canvas.restore();

    // 캐릭터 (화면 좌표)
    _drawCharacter(canvas, charX, charY);
  }

  void _drawDoor(Canvas canvas) {
    final rect = Rect.fromLTWH(doorX, doorY, doorWidth, doorHeight);

    // 문 배경
    final doorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.brown[800]!, Colors.brown[900]!],
      ).createShader(rect);

    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(rrect, doorPaint);

    // 문 테두리
    final borderPaint = Paint()
      ..color = Colors.brown[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // 글로우
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect, glowPaint);

    // 출구 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🚪 출구',
        style: TextStyle(fontSize: 16, color: Colors.brown[300]),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        doorX + (doorWidth - textPainter.width) / 2,
        doorY + (doorHeight - textPainter.height) / 2,
      ),
    );
  }

  void _drawOwnerLabel(Canvas canvas) {
    final labelColor = isChiefHouse ? Colors.orangeAccent : Colors.cyanAccent;

    // 배경
    final bgPaint = Paint()..color = Colors.black54;
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 16, 150, 32),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = labelColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bgRect, borderPaint);

    // 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🏠 $ownerName의 집',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(26, 22));
  }

  void _drawCharacter(Canvas canvas, double x, double y) {
    canvas.save();
    canvas.translate(x, y);

    // 좌우 반전
    if (!facingRight) {
      canvas.scale(-1, 1);
    }

    // 캐릭터 크기: 60x84 (250:350 비율)
    const charWidth = 60.0;
    const charHeight = 84.0;

    canvas.translate(-charWidth / 2, -charHeight / 2);

    if (visitorStrokes.isNotEmpty) {
      // main.dart의 CustomCharacterPainter를 직접 사용하여 마을과 동일한 애니메이션 적용
      final characterPainter = main_app.CustomCharacterPainter(
        strokes: visitorStrokes,
        originalSize: const Size(250, 350),
        animationValue: animationValue,
        isMoving: isMoving,
        isRunning: false, // 집 안에서는 달리기 없음
      );
      characterPainter.paint(canvas, const Size(charWidth, charHeight));
    } else {
      // 기본 스틱맨 - 마을과 동일한 StickmanPainter 사용
      final stickmanPainter = main_app.StickmanPainter(
        animationValue: animationValue,
        isMoving: isMoving,
        isRunning: false,
      );
      stickmanPainter.paint(canvas, const Size(charWidth, charHeight));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoomViewPainter oldDelegate) {
    return oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.charX != charX ||
        oldDelegate.charY != charY ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.facingRight != facingRight;
  }
}
