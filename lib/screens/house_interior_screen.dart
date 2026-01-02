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
  // 내부 공간 크기
  static const double roomWidth = 600;
  static const double roomHeight = 500;

  // 캐릭터 위치 (문 앞에서 시작)
  double _charX = roomWidth / 2;
  double _charY = roomHeight - 80;

  // 이동 관련
  bool _isMoving = false;
  bool _facingRight = true;
  double _targetX = 0;
  double _targetY = 0;

  // 애니메이션
  late AnimationController _walkController;
  AnimationController? _moveController;
  Animation<double>? _moveAnimation;

  // 문 영역 (하단 중앙)
  static const double doorWidth = 80;
  static const double doorHeight = 100;
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
    // 경계 내로 제한
    final targetX = target.dx.clamp(30.0, roomWidth - 30.0);
    final targetY = target.dy.clamp(50.0, roomHeight - 50.0);

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

            // 방 내부
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTapDown: (details) {
                    _moveCharacter(details.localPosition);
                  },
                  child: Container(
                    width: roomWidth,
                    height: roomHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          // 바닥
                          CustomPaint(
                            size: const Size(roomWidth, roomHeight),
                            painter: _RoomFloorPainter(),
                          ),

                          // 문
                          Positioned(
                            left: doorX,
                            top: doorY,
                            child: _buildDoor(),
                          ),

                          // 캐릭터
                          Positioned(
                            left: _charX - 30,
                            top: _charY - 50,
                            child: _buildCharacter(),
                          ),

                          // 집 주인 표시
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.house.isChiefHouse
                                      ? Colors.orangeAccent
                                      : Colors.cyanAccent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.home,
                                    size: 16,
                                    color: widget.house.isChiefHouse
                                        ? Colors.orangeAccent
                                        : Colors.cyanAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.house.ownerName}의 집',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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

  Widget _buildDoor() {
    return Container(
      width: doorWidth,
      height: doorHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown[800]!,
            Colors.brown[900]!,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(
          color: Colors.brown[600]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.door_front_door,
            color: Colors.brown[400],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            '출구',
            style: TextStyle(
              color: Colors.brown[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    return Column(
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_facingRight ? 1.0 : -1.0, 1.0, 1.0),
          child: AnimatedBuilder(
            animation: _walkController,
            builder: (context, child) {
              if (widget.visitorStrokes.isNotEmpty) {
                // 마을과 동일한 CustomCharacterPainter 사용
                return CustomPaint(
                  size: const Size(60, 84), // 250:350 비율 유지
                  painter: main_app.CustomCharacterPainter(
                    strokes: widget.visitorStrokes,
                    isMoving: _isMoving,
                    animationValue: _walkController.value,
                  ),
                );
              }
              // 기본 스틱맨
              return CustomPaint(
                size: const Size(60, 84),
                painter: _DefaultStickmanPainter(
                  isMoving: _isMoving,
                  animationValue: _walkController.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.visitorName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// 방 바닥 그리기
class _RoomFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 바닥 타일 패턴
    final tilePaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1;

    // 바닥 채우기
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tilePaint);

    // 타일 라인
    const tileSize = 50.0;
    for (double x = 0; x <= size.width; x += tileSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }
    for (double y = 0; y <= size.height; y += tileSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // 벽 (상단)
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[900]!,
          Colors.grey[850]!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 80), wallPaint);

    // 벽 하단 라인
    final wallLinePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(0, 80),
      Offset(size.width, 80),
      wallLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 기본 스틱맨 페인터
class _DefaultStickmanPainter extends CustomPainter {
  final bool isMoving;
  final double animationValue;

  _DefaultStickmanPainter({
    required this.isMoving,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    // 머리
    canvas.drawCircle(Offset(centerX, 15), 12, paint);

    // 몸통
    canvas.drawLine(
      Offset(centerX, 27),
      Offset(centerX, 55),
      paint,
    );

    // 걷기 애니메이션
    final legSwing = isMoving ? sin(animationValue * 2 * pi) * 15 : 0;
    final armSwing = isMoving ? sin(animationValue * 2 * pi) * 10 : 0;

    // 팔
    canvas.drawLine(
      Offset(centerX, 35),
      Offset(centerX - 15 + armSwing, 50),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, 35),
      Offset(centerX + 15 - armSwing, 50),
      paint,
    );

    // 다리
    canvas.drawLine(
      Offset(centerX, 55),
      Offset(centerX - 12 + legSwing, 85),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, 55),
      Offset(centerX + 12 - legSwing, 85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DefaultStickmanPainter oldDelegate) {
    return oldDelegate.isMoving != isMoving ||
        oldDelegate.animationValue != animationValue;
  }
}
