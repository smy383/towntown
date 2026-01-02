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
  // 캐릭터 위치 (0~1 비율로 관리)
  double _charX = 0.5; // 중앙
  double _charY = 0.5; // 중앙

  // 이동 관련
  bool _isMoving = false;
  bool _facingRight = true;
  double _targetX = 0.5;
  double _targetY = 0.5;

  // 애니메이션
  late AnimationController _walkController;
  AnimationController? _moveController;
  Animation<double>? _moveAnimation;

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

  void _moveCharacter(double targetXRatio, double targetYRatio) {
    // 경계 내로 제한 (상단 벽 영역 제외, 문 영역 제외)
    final targetX = targetXRatio.clamp(0.1, 0.9);
    final targetY = targetYRatio.clamp(0.15, 0.75); // 상단 벽, 하단 문 영역 제외

    // 현재 위치와 같으면 이동하지 않음
    if ((targetX - _charX).abs() < 0.01 && (targetY - _charY).abs() < 0.01) {
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

    // 거리에 따른 이동 시간 (비율 기준이므로 적절히 조절)
    final duration = Duration(milliseconds: (distance * 2000).toInt().clamp(200, 2000));

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
    // 문은 하단 중앙 (x: 0.35~0.65, y: 0.75 이상)
    return _charX >= 0.35 && _charX <= 0.65 && _charY >= 0.7;
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

            // 방 내부 - 최대 크기 제한 및 중앙 정렬
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                    maxHeight: 800,
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.75, // 3:4 비율
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final roomW = constraints.maxWidth;
                        final roomH = constraints.maxHeight;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF424242), // 바닥색
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 배경 터치 영역 (가장 먼저)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (details) {
                                    final tapX = details.localPosition.dx / roomW;
                                    final tapY = details.localPosition.dy / roomH;
                                    _moveCharacter(tapX, tapY);
                                  },
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                                // 벽 (상단)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    height: roomH * 0.12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF212121),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                // 문 (하단 중앙)
                                Positioned(
                                  left: roomW * 0.35,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () => _showExitDialog(),
                                    child: Container(
                                      width: roomW * 0.3,
                                      height: roomH * 0.22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4E342E),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                        border: Border.all(
                                          color: Colors.cyanAccent,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '출구',
                                          style: TextStyle(
                                            color: Color(0xFFBCAAA4),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // 집 주인 표시
                                Positioned(
                                  left: 16,
                                  top: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: widget.house.isChiefHouse
                                            ? Colors.orangeAccent
                                            : Colors.cyanAccent,
                                      ),
                                    ),
                                    child: Text(
                                      '${widget.house.ownerName}의 집',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // 캐릭터 (이동 가능)
                                AnimatedBuilder(
                                  animation: _walkController,
                                  builder: (context, child) {
                                    final charWidth = 60.0;
                                    final charHeight = 84.0;

                                    return Positioned(
                                      left: _charX * roomW - charWidth / 2,
                                      top: _charY * roomH - charHeight / 2,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: charWidth,
                                              height: charHeight,
                                              child: widget.visitorStrokes.isNotEmpty
                                                  ? CustomPaint(
                                                      painter: main_app.CustomCharacterPainter(
                                                        strokes: widget.visitorStrokes,
                                                        animationValue: _walkController.value,
                                                        isMoving: _isMoving,
                                                        isRunning: false,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                            ),
                                            const SizedBox(height: 4),
                                            Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                                              child: Text(
                                                widget.visitorName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        );
                      },
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

}
