import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const TownTownApp());
}

class TownTownApp extends StatelessWidget {
  const TownTownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TownTown',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CreateCharacterScreen(),
    );
  }
}

/// 캐릭터 만들기 화면
class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _previewAnimController;

  @override
  void initState() {
    super.initState();
    _previewAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _previewAnimController.dispose();
    super.dispose();
  }

  void _createCharacter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterDesignScreen(characterName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '캐릭터 만들기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // 졸라맨 미리보기
              AnimatedBuilder(
                animation: _previewAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(80, 120),
                    painter: StickmanPainter(
                      animationValue: _previewAnimController.value,
                      isMoving: true,
                      isRunning: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // 이름 입력
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '캐릭터 이름',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 시작 버튼
              ElevatedButton(
                onPressed: _createCharacter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  '마을로 가기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 그리기 선 데이터
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 3.0,
  });
}

/// 캐릭터 디자인 화면
class CharacterDesignScreen extends StatefulWidget {
  final String characterName;

  const CharacterDesignScreen({super.key, required this.characterName});

  @override
  State<CharacterDesignScreen> createState() => _CharacterDesignScreenState();
}

class _CharacterDesignScreenState extends State<CharacterDesignScreen> {
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;

  // 색상 팔레트
  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    final localPos = _getLocalPosition(details.localPosition, canvasSize);
    if (localPos != null) {
      setState(() {
        _currentStroke = [localPos];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    final localPos = _getLocalPosition(details.localPosition, canvasSize);
    if (localPos != null && _currentStroke.isNotEmpty) {
      setState(() {
        _currentStroke.add(localPos);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(DrawingStroke(
          points: List.from(_currentStroke),
          color: _currentColor,
          strokeWidth: _strokeWidth,
        ));
        _currentStroke = [];
      });
    }
  }

  // 캔버스 영역 내의 좌표로 변환
  Offset? _getLocalPosition(Offset position, Size canvasSize) {
    if (position.dx >= 0 &&
        position.dx <= canvasSize.width &&
        position.dy >= 0 &&
        position.dy <= canvasSize.height) {
      return position;
    }
    return null;
  }

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _undoLastStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const canvasSize = Size(250, 350);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${widget.characterName} 꾸미기'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastStroke,
            tooltip: '되돌리기',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearDrawing,
            tooltip: '전체 지우기',
          ),
        ],
      ),
      body: Column(
        children: [
          // 색상 팔레트
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _colors.map((color) {
                final isSelected = _currentColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _currentColor = color),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.yellow : Colors.white30,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 브러시 크기
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                const Text('굵기', style: TextStyle(color: Colors.white54)),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 15,
                    onChanged: (value) => setState(() => _strokeWidth = value),
                  ),
                ),
                Container(
                  width: _strokeWidth,
                  height: _strokeWidth,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 캔버스
          Expanded(
            child: Center(
              child: GestureDetector(
                onPanStart: (d) => _onPanStart(d, canvasSize),
                onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                onPanEnd: _onPanEnd,
                child: Container(
                  width: canvasSize.width,
                  height: canvasSize.height,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      size: canvasSize,
                      painter: DrawingCanvasPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        currentColor: _currentColor,
                        currentStrokeWidth: _strokeWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 마을로 가기 버튼
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VillageLand(
                      characterName: widget.characterName,
                      characterStrokes: _strokes,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('마을로 가기', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 그리기 캔버스 (실루엣 + 사용자 그림)
class DrawingCanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  DrawingCanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 실루엣 먼저 그리기
    BodyCharacterPainter().paint(canvas, size);

    // 2. 저장된 선들 그리기
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }

    // 3. 현재 그리는 중인 선
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      // 점 하나만 찍은 경우
      canvas.drawCircle(points[0], width / 2, paint..style = PaintingStyle.fill);
    } else {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}

/// 하얀색 실루엣 캐릭터 (뼈대 위에 파츠 형태)
class BodyCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 하얀색 실루엣
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 회색 외곽선 (파츠 구분용)
    final outlinePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // === 파츠 치수 ===
    final headRadius = size.width * 0.20;
    final headY = size.height * 0.13;

    final neckTop = headY + headRadius;
    final shoulderY = neckTop + size.height * 0.02;

    final torsoHeight = size.height * 0.28;
    final torsoWidth = size.width * 0.38;
    final hipY = shoulderY + torsoHeight;

    final shoulderWidth = size.width * 0.22;
    final armWidth = size.width * 0.10;
    final upperArmLength = size.height * 0.14;
    final lowerArmLength = size.height * 0.13;

    final hipWidth = size.width * 0.08;
    final legWidth = size.width * 0.12;
    final upperLegLength = size.height * 0.17;
    final lowerLegLength = size.height * 0.16;

    // === 왼쪽 다리 (뒤) ===
    final leftLegX = cx - hipWidth;
    final leftKneeY = hipY + upperLegLength;
    final leftFootY = leftKneeY + lowerLegLength;

    // 왼쪽 허벅지
    _drawRoundedLimb(canvas,
      Offset(leftLegX, hipY),
      Offset(leftLegX - 2, leftKneeY),
      legWidth, fillPaint, outlinePaint);
    // 왼쪽 종아리
    _drawRoundedLimb(canvas,
      Offset(leftLegX - 2, leftKneeY),
      Offset(leftLegX - 2, leftFootY),
      legWidth * 0.85, fillPaint, outlinePaint);

    // === 오른쪽 다리 (뒤) ===
    final rightLegX = cx + hipWidth;
    final rightKneeY = hipY + upperLegLength;
    final rightFootY = rightKneeY + lowerLegLength;

    // 오른쪽 허벅지
    _drawRoundedLimb(canvas,
      Offset(rightLegX, hipY),
      Offset(rightLegX + 2, rightKneeY),
      legWidth, fillPaint, outlinePaint);
    // 오른쪽 종아리
    _drawRoundedLimb(canvas,
      Offset(rightLegX + 2, rightKneeY),
      Offset(rightLegX + 2, rightFootY),
      legWidth * 0.85, fillPaint, outlinePaint);

    // === 몸통 ===
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, shoulderY + torsoHeight / 2),
        width: torsoWidth,
        height: torsoHeight,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(torsoRect, fillPaint);
    canvas.drawRRect(torsoRect, outlinePaint);

    // === 왼쪽 팔 ===
    final leftShoulderX = cx - shoulderWidth;
    final leftElbowX = leftShoulderX - upperArmLength * 0.3;
    final leftElbowY = shoulderY + upperArmLength;
    final leftHandX = leftElbowX - lowerArmLength * 0.15;
    final leftHandY = leftElbowY + lowerArmLength;

    // 왼쪽 상완
    _drawRoundedLimb(canvas,
      Offset(leftShoulderX, shoulderY + 8),
      Offset(leftElbowX, leftElbowY),
      armWidth, fillPaint, outlinePaint);
    // 왼쪽 하완
    _drawRoundedLimb(canvas,
      Offset(leftElbowX, leftElbowY),
      Offset(leftHandX, leftHandY),
      armWidth * 0.85, fillPaint, outlinePaint);

    // === 오른쪽 팔 ===
    final rightShoulderX = cx + shoulderWidth;
    final rightElbowX = rightShoulderX + upperArmLength * 0.3;
    final rightElbowY = shoulderY + upperArmLength;
    final rightHandX = rightElbowX + lowerArmLength * 0.15;
    final rightHandY = rightElbowY + lowerArmLength;

    // 오른쪽 상완
    _drawRoundedLimb(canvas,
      Offset(rightShoulderX, shoulderY + 8),
      Offset(rightElbowX, rightElbowY),
      armWidth, fillPaint, outlinePaint);
    // 오른쪽 하완
    _drawRoundedLimb(canvas,
      Offset(rightElbowX, rightElbowY),
      Offset(rightHandX, rightHandY),
      armWidth * 0.85, fillPaint, outlinePaint);

    // === 머리 ===
    canvas.drawCircle(Offset(cx, headY), headRadius, fillPaint);
    canvas.drawCircle(Offset(cx, headY), headRadius, outlinePaint);
  }

  // 둥근 끝의 팔/다리 그리기
  void _drawRoundedLimb(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    Paint fillPaint,
    Paint outlinePaint,
  ) {
    // 둥근 끝 캡이 있는 두꺼운 선
    final limbPaint = Paint()
      ..color = fillPaint.color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, limbPaint);

    // 외곽선
    final outlineStroke = Paint()
      ..color = outlinePaint.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 외곽 경로 계산
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final perpX = -dy / length * (width / 2);
    final perpY = dx / length * (width / 2);

    final path = Path();
    // 시작점 반원
    path.addArc(
      Rect.fromCircle(center: start, radius: width / 2),
      atan2(-perpY, -perpX),
      pi,
    );
    // 오른쪽 선
    path.lineTo(end.dx + perpX, end.dy + perpY);
    // 끝점 반원
    path.addArc(
      Rect.fromCircle(center: end, radius: width / 2),
      atan2(perpY, perpX),
      pi,
    );
    // 왼쪽 선
    path.lineTo(start.dx - perpX, start.dy - perpY);
    path.close();

    canvas.drawPath(path, outlineStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 관절 위치를 계산하는 헬퍼
class Joint {
  final double x;
  final double y;

  Joint(this.x, this.y);

  Joint rotate(double angle, double length) {
    return Joint(
      x + cos(angle) * length,
      y + sin(angle) * length,
    );
  }
}

/// 걷기/달리기 포즈 데이터
class WalkCycle {
  static Map<String, double> getPose(double t, bool isRunning) {
    final cycle = t % 1.0;
    final phase = cycle * pi * 2;

    // 강도 설정
    final hipSwing = isRunning ? 0.6 : 0.35;
    final bounce = isRunning ? 0.06 : 0.02;

    // 몸통
    final bodyBounce = sin(phase * 2).abs() * bounce;
    final bodyLean = isRunning ? 0.12 : 0.03;

    // === 왼쪽 다리 ===
    // 엉덩이: 앞뒤로 스윙
    final leftHipAngle = sin(phase) * hipSwing;
    // 무릎: 다리가 앞으로 올 때만 굽힘 (항상 양수, 뒤로 안 꺾임)
    final leftLegForward = sin(phase);
    final leftKneeBend = leftLegForward > 0
        ? leftLegForward * (isRunning ? 1.2 : 0.6)  // 앞으로 갈 때 무릎 굽힘
        : 0.1;  // 뒤로 갈 때는 거의 펴짐

    // === 오른쪽 다리 (반대 위상) ===
    final rightHipAngle = sin(phase + pi) * hipSwing;
    final rightLegForward = sin(phase + pi);
    final rightKneeBend = rightLegForward > 0
        ? rightLegForward * (isRunning ? 1.2 : 0.6)
        : 0.1;

    // === 왼쪽 팔 (오른다리와 같이 움직임) ===
    final leftArmSwing = sin(phase + pi) * (isRunning ? 0.7 : 0.4);
    // 팔꿈치: 팔이 뒤로 갈 때 더 굽힘
    final leftElbowBend = 0.4 + (sin(phase + pi) < 0 ? -sin(phase + pi) * 0.5 : 0.1);

    // === 오른쪽 팔 ===
    final rightArmSwing = sin(phase) * (isRunning ? 0.7 : 0.4);
    final rightElbowBend = 0.4 + (sin(phase) < 0 ? -sin(phase) * 0.5 : 0.1);

    return {
      'bodyBounce': bodyBounce,
      'bodyLean': bodyLean,
      'leftHip': leftHipAngle,
      'leftKnee': leftKneeBend,
      'rightHip': rightHipAngle,
      'rightKnee': rightKneeBend,
      'leftShoulder': leftArmSwing,
      'leftElbow': leftElbowBend,
      'rightShoulder': rightArmSwing,
      'rightElbow': rightElbowBend,
    };
  }
}

/// 졸라맨 그리기 (관절 시스템)
class StickmanPainter extends CustomPainter {
  final double animationValue;
  final bool isMoving;
  final bool isRunning;

  StickmanPainter({
    required this.animationValue,
    required this.isMoving,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 기본 치수
    final cx = size.width / 2;
    final headRadius = size.width * 0.12;
    final neckLength = size.height * 0.05;
    final torsoLength = size.height * 0.25;
    final upperArmLength = size.height * 0.15;
    final lowerArmLength = size.height * 0.12;
    final upperLegLength = size.height * 0.18;
    final lowerLegLength = size.height * 0.18;

    // 서 있을 때는 정면 뷰
    if (!isMoving) {
      _drawFrontView(canvas, size, paint, headPaint, cx, headRadius,
          neckLength, torsoLength, upperArmLength, lowerArmLength,
          upperLegLength, lowerLegLength);
      return;
    }

    // 포즈 가져오기
    final pose = isMoving
        ? WalkCycle.getPose(animationValue, isRunning)
        : WalkCycle.getPose(0, false);

    // 기준점 (엉덩이)
    final hipY = size.height * 0.45 + (isMoving ? pose['bodyBounce']! * size.height : 0);
    final hip = Joint(cx, hipY);

    // 몸통 기울기 적용
    final lean = isMoving ? pose['bodyLean']! : 0.0;

    // 어깨 위치
    final shoulderY = hipY - torsoLength;
    final shoulderX = cx + sin(lean) * torsoLength * 0.3;
    final shoulder = Joint(shoulderX, shoulderY);

    // 목/머리
    final neckTop = Joint(shoulderX + sin(lean) * neckLength, shoulderY - neckLength);
    final headCenter = Joint(neckTop.x, neckTop.y - headRadius);

    // 머리 그리기
    canvas.drawCircle(Offset(headCenter.x, headCenter.y), headRadius, headPaint);

    // 목 그리기
    canvas.drawLine(
      Offset(shoulder.x, shoulder.y),
      Offset(neckTop.x, neckTop.y),
      paint,
    );

    // 몸통 그리기
    canvas.drawLine(
      Offset(shoulder.x, shoulder.y),
      Offset(hip.x, hip.y),
      paint,
    );

    // 어깨 너비 (양쪽으로 팔이 나옴)
    final shoulderWidth = size.width * 0.18;
    final leftShoulderJoint = Joint(shoulder.x - shoulderWidth, shoulder.y);
    final rightShoulderJoint = Joint(shoulder.x + shoulderWidth, shoulder.y);

    // === 어깨선 그리기 ===
    canvas.drawLine(
      Offset(leftShoulderJoint.x, leftShoulderJoint.y),
      Offset(rightShoulderJoint.x, rightShoulderJoint.y),
      paint,
    );

    // === 왼쪽 팔 ===
    final leftArmSwing = isMoving ? pose['leftShoulder']! : 0.0;
    final leftUpperArmAngle = pi / 2 - leftArmSwing;
    final leftElbowPos = leftShoulderJoint.rotate(leftUpperArmAngle, upperArmLength);

    // 팔꿈치: 항상 앞쪽(-방향)으로만 굽혀짐
    final leftElbowBend = isMoving ? pose['leftElbow']! : 0.3;
    final leftHandAngle = leftUpperArmAngle - leftElbowBend;
    final leftHand = leftElbowPos.rotate(leftHandAngle, lowerArmLength);

    canvas.drawLine(
      Offset(leftShoulderJoint.x, leftShoulderJoint.y),
      Offset(leftElbowPos.x, leftElbowPos.y),
      paint,
    );
    canvas.drawLine(
      Offset(leftElbowPos.x, leftElbowPos.y),
      Offset(leftHand.x, leftHand.y),
      paint,
    );

    // === 오른쪽 팔 ===
    final rightArmSwing = isMoving ? pose['rightShoulder']! : 0.0;
    final rightUpperArmAngle = pi / 2 - rightArmSwing;
    final rightElbowPos = rightShoulderJoint.rotate(rightUpperArmAngle, upperArmLength);

    // 팔꿈치: 항상 앞쪽(-방향)으로만 굽혀짐
    final rightElbowBend = isMoving ? pose['rightElbow']! : 0.3;
    final rightHandAngle = rightUpperArmAngle - rightElbowBend;
    final rightHand = rightElbowPos.rotate(rightHandAngle, lowerArmLength);

    canvas.drawLine(
      Offset(rightShoulderJoint.x, rightShoulderJoint.y),
      Offset(rightElbowPos.x, rightElbowPos.y),
      paint,
    );
    canvas.drawLine(
      Offset(rightElbowPos.x, rightElbowPos.y),
      Offset(rightHand.x, rightHand.y),
      paint,
    );

    // === 왼쪽 다리 ===
    final leftHipAngle = pi / 2 + (isMoving ? pose['leftHip']! : 0);
    final leftKneePos = hip.rotate(leftHipAngle, upperLegLength);

    // 무릎은 허벅지 방향 기준으로 항상 뒤쪽(양수)으로만 굽힘
    final leftKneeBend = isMoving ? pose['leftKnee']!.abs() : 0.0;
    final leftFootAngle = leftHipAngle + leftKneeBend;
    final leftFoot = leftKneePos.rotate(leftFootAngle, lowerLegLength);

    canvas.drawLine(
      Offset(hip.x, hip.y),
      Offset(leftKneePos.x, leftKneePos.y),
      paint,
    );
    canvas.drawLine(
      Offset(leftKneePos.x, leftKneePos.y),
      Offset(leftFoot.x, leftFoot.y),
      paint,
    );

    // === 오른쪽 다리 ===
    final rightHipAngle = pi / 2 + (isMoving ? pose['rightHip']! : 0);
    final rightKneePos = hip.rotate(rightHipAngle, upperLegLength);

    final rightKneeBend = isMoving ? pose['rightKnee']!.abs() : 0.0;
    final rightFootAngle = rightHipAngle + rightKneeBend;
    final rightFoot = rightKneePos.rotate(rightFootAngle, lowerLegLength);

    canvas.drawLine(
      Offset(hip.x, hip.y),
      Offset(rightKneePos.x, rightKneePos.y),
      paint,
    );
    canvas.drawLine(
      Offset(rightKneePos.x, rightKneePos.y),
      Offset(rightFoot.x, rightFoot.y),
      paint,
    );
  }

  // 정면 뷰 그리기
  void _drawFrontView(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint headPaint,
    double cx,
    double headRadius,
    double neckLength,
    double torsoLength,
    double upperArmLength,
    double lowerArmLength,
    double upperLegLength,
    double lowerLegLength,
  ) {
    // 머리
    final headY = size.height * 0.12;
    canvas.drawCircle(Offset(cx, headY), headRadius, headPaint);

    // 목
    final neckTop = headY + headRadius;
    final shoulderY = neckTop + neckLength;
    canvas.drawLine(Offset(cx, neckTop), Offset(cx, shoulderY), paint);

    // 몸통
    final hipY = shoulderY + torsoLength;
    canvas.drawLine(Offset(cx, shoulderY), Offset(cx, hipY), paint);

    // 어깨선
    final shoulderWidth = size.width * 0.25;
    canvas.drawLine(
      Offset(cx - shoulderWidth, shoulderY),
      Offset(cx + shoulderWidth, shoulderY),
      paint,
    );

    // 왼쪽 팔 (정면에서 볼 때 약간 벌어짐)
    final leftShoulderX = cx - shoulderWidth;
    final leftElbowX = leftShoulderX - upperArmLength * 0.3;
    final leftElbowY = shoulderY + upperArmLength * 0.9;
    final leftHandX = leftElbowX - lowerArmLength * 0.2;
    final leftHandY = leftElbowY + lowerArmLength * 0.95;
    canvas.drawLine(Offset(leftShoulderX, shoulderY), Offset(leftElbowX, leftElbowY), paint);
    canvas.drawLine(Offset(leftElbowX, leftElbowY), Offset(leftHandX, leftHandY), paint);

    // 오른쪽 팔
    final rightShoulderX = cx + shoulderWidth;
    final rightElbowX = rightShoulderX + upperArmLength * 0.3;
    final rightElbowY = shoulderY + upperArmLength * 0.9;
    final rightHandX = rightElbowX + lowerArmLength * 0.2;
    final rightHandY = rightElbowY + lowerArmLength * 0.95;
    canvas.drawLine(Offset(rightShoulderX, shoulderY), Offset(rightElbowX, rightElbowY), paint);
    canvas.drawLine(Offset(rightElbowX, rightElbowY), Offset(rightHandX, rightHandY), paint);

    // 왼쪽 다리
    final hipWidth = size.width * 0.1;
    final leftKneeX = cx - hipWidth - upperLegLength * 0.15;
    final leftKneeY = hipY + upperLegLength * 0.95;
    final leftFootX = leftKneeX;
    final leftFootY = leftKneeY + lowerLegLength;
    canvas.drawLine(Offset(cx - hipWidth, hipY), Offset(leftKneeX, leftKneeY), paint);
    canvas.drawLine(Offset(leftKneeX, leftKneeY), Offset(leftFootX, leftFootY), paint);

    // 오른쪽 다리
    final rightKneeX = cx + hipWidth + upperLegLength * 0.15;
    final rightKneeY = hipY + upperLegLength * 0.95;
    final rightFootX = rightKneeX;
    final rightFootY = rightKneeY + lowerLegLength;
    canvas.drawLine(Offset(cx + hipWidth, hipY), Offset(rightKneeX, rightKneeY), paint);
    canvas.drawLine(Offset(rightKneeX, rightKneeY), Offset(rightFootX, rightFootY), paint);
  }

  @override
  bool shouldRepaint(covariant StickmanPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.isRunning != isRunning;
  }
}

/// 신체 부위 영역 정의 (원본 캔버스 250x350 기준)
class BodyPartRegions {
  static const Size canvasSize = Size(250, 350);

  // 각 부위의 중심점과 영역 (원본 BodyCharacterPainter 기준)
  static Rect get head {
    final cx = canvasSize.width / 2;
    final headRadius = canvasSize.width * 0.20;
    final headY = canvasSize.height * 0.13;
    return Rect.fromCircle(center: Offset(cx, headY), radius: headRadius + 5);
  }

  static Rect get torso {
    final cx = canvasSize.width / 2;
    final headRadius = canvasSize.width * 0.20;
    final headY = canvasSize.height * 0.13;
    final neckTop = headY + headRadius;
    final shoulderY = neckTop + canvasSize.height * 0.02;
    final torsoHeight = canvasSize.height * 0.28;
    final torsoWidth = canvasSize.width * 0.38;
    return Rect.fromCenter(
      center: Offset(cx, shoulderY + torsoHeight / 2),
      width: torsoWidth + 10,
      height: torsoHeight + 10,
    );
  }

  static Rect get leftArm {
    final cx = canvasSize.width / 2;
    final shoulderWidth = canvasSize.width * 0.22;
    return Rect.fromLTRB(0, torso.top - 10, cx - shoulderWidth + 30, torso.bottom + 40);
  }

  static Rect get rightArm {
    final cx = canvasSize.width / 2;
    final shoulderWidth = canvasSize.width * 0.22;
    return Rect.fromLTRB(cx + shoulderWidth - 30, torso.top - 10, canvasSize.width, torso.bottom + 40);
  }

  static Rect get leftLeg {
    final cx = canvasSize.width / 2;
    return Rect.fromLTRB(0, torso.bottom - 20, cx, canvasSize.height);
  }

  static Rect get rightLeg {
    final cx = canvasSize.width / 2;
    return Rect.fromLTRB(cx, torso.bottom - 20, canvasSize.width, canvasSize.height);
  }

  // 점이 어느 부위에 속하는지 판단
  static String getBodyPart(Offset point) {
    if (head.contains(point)) return 'head';
    if (leftArm.contains(point)) return 'leftArm';
    if (rightArm.contains(point)) return 'rightArm';
    if (torso.contains(point)) return 'torso';
    if (leftLeg.contains(point)) return 'leftLeg';
    if (rightLeg.contains(point)) return 'rightLeg';
    return 'torso'; // 기본값
  }

  // 각 부위의 피벗 포인트 (회전 중심)
  static Offset getPivot(String part) {
    final cx = canvasSize.width / 2;
    final headRadius = canvasSize.width * 0.20;
    final headY = canvasSize.height * 0.13;
    final neckTop = headY + headRadius;
    final shoulderY = neckTop + canvasSize.height * 0.02;
    final shoulderWidth = canvasSize.width * 0.22;
    final torsoHeight = canvasSize.height * 0.28;
    final hipY = shoulderY + torsoHeight;

    switch (part) {
      case 'head':
        return Offset(cx, headY + headRadius); // 목 위치
      case 'leftArm':
        return Offset(cx - shoulderWidth, shoulderY + 8); // 왼쪽 어깨
      case 'rightArm':
        return Offset(cx + shoulderWidth, shoulderY + 8); // 오른쪽 어깨
      case 'leftLeg':
        return Offset(cx - canvasSize.width * 0.08, hipY); // 왼쪽 골반
      case 'rightLeg':
        return Offset(cx + canvasSize.width * 0.08, hipY); // 오른쪽 골반
      default:
        return Offset(cx, shoulderY + torsoHeight / 2); // 몸통 중심
    }
  }
}

/// 마을에서 사용할 사용자 정의 캐릭터 (애니메이션 포함)
class CustomCharacterPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final Size originalSize;
  final double animationValue;
  final bool isMoving;
  final bool isRunning;

  CustomCharacterPainter({
    required this.strokes,
    this.originalSize = const Size(250, 350),
    this.animationValue = 0,
    this.isMoving = false,
    this.isRunning = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 스케일 계산
    final scaleX = size.width / originalSize.width;
    final scaleY = size.height / originalSize.height;
    final scale = min(scaleX, scaleY);

    // 중앙 정렬을 위한 오프셋
    final offsetX = (size.width - originalSize.width * scale) / 2;
    final offsetY = (size.height - originalSize.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // 걷기 포즈 계산
    final pose = isMoving
        ? WalkCycle.getPose(animationValue, isRunning)
        : <String, double>{
            'bodyBounce': 0.0,
            'leftHip': 0.0, 'leftKnee': 0.0,
            'rightHip': 0.0, 'rightKnee': 0.0,
            'leftShoulder': 0.0, 'leftElbow': 0.0,
            'rightShoulder': 0.0, 'rightElbow': 0.0,
          };

    // 몸통 바운스
    final bodyBounce = isMoving ? pose['bodyBounce']! * originalSize.height : 0.0;

    // 1. 실루엣 + 사용자 그림을 부위별로 그리기
    _drawBodyPart(canvas, 'leftLeg', pose, bodyBounce);
    _drawBodyPart(canvas, 'rightLeg', pose, bodyBounce);
    _drawBodyPart(canvas, 'torso', pose, bodyBounce);
    _drawBodyPart(canvas, 'leftArm', pose, bodyBounce);
    _drawBodyPart(canvas, 'rightArm', pose, bodyBounce);
    _drawBodyPart(canvas, 'head', pose, bodyBounce);

    canvas.restore();
  }

  void _drawBodyPart(Canvas canvas, String part, Map<String, double> pose, double bodyBounce) {
    canvas.save();

    final pivot = BodyPartRegions.getPivot(part);
    double rotation = 0;
    double translateY = bodyBounce;

    // 부위별 회전/변환 적용
    if (isMoving) {
      switch (part) {
        case 'leftArm':
          rotation = pose['leftShoulder']! * 0.4;
          break;
        case 'rightArm':
          rotation = pose['rightShoulder']! * 0.4;
          break;
        case 'leftLeg':
          rotation = pose['leftHip']! * 0.3;
          break;
        case 'rightLeg':
          rotation = pose['rightHip']! * 0.3;
          break;
        case 'head':
        case 'torso':
          // 약간의 좌우 흔들림
          rotation = sin(animationValue * pi * 2) * 0.02;
          break;
      }
    }

    // 변환 적용
    canvas.translate(pivot.dx, pivot.dy + translateY);
    canvas.rotate(rotation);
    canvas.translate(-pivot.dx, -pivot.dy - translateY);
    canvas.translate(0, translateY);

    // 해당 부위의 실루엣 그리기
    _drawSilhouettePart(canvas, part);

    // 해당 부위에 속하는 스트로크 그리기
    for (final stroke in strokes) {
      final partPoints = <Offset>[];
      for (final point in stroke.points) {
        if (BodyPartRegions.getBodyPart(point) == part) {
          partPoints.add(point);
        }
      }
      if (partPoints.isNotEmpty) {
        _drawStroke(canvas, partPoints, stroke.color, stroke.strokeWidth);
      }
    }

    canvas.restore();
  }

  void _drawSilhouettePart(Canvas canvas, String part) {
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cx = originalSize.width / 2;
    final headRadius = originalSize.width * 0.20;
    final headY = originalSize.height * 0.13;
    final neckTop = headY + headRadius;
    final shoulderY = neckTop + originalSize.height * 0.02;
    final torsoHeight = originalSize.height * 0.28;
    final torsoWidth = originalSize.width * 0.38;
    final hipY = shoulderY + torsoHeight;
    final shoulderWidth = originalSize.width * 0.22;
    final armWidth = originalSize.width * 0.10;
    final upperArmLength = originalSize.height * 0.14;
    final lowerArmLength = originalSize.height * 0.13;
    final hipWidth = originalSize.width * 0.08;
    final legWidth = originalSize.width * 0.12;
    final upperLegLength = originalSize.height * 0.17;
    final lowerLegLength = originalSize.height * 0.16;

    switch (part) {
      case 'head':
        canvas.drawCircle(Offset(cx, headY), headRadius, fillPaint);
        canvas.drawCircle(Offset(cx, headY), headRadius, outlinePaint);
        break;

      case 'torso':
        final torsoRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, shoulderY + torsoHeight / 2),
            width: torsoWidth,
            height: torsoHeight,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(torsoRect, fillPaint);
        canvas.drawRRect(torsoRect, outlinePaint);
        break;

      case 'leftArm':
        final leftShoulderX = cx - shoulderWidth;
        final leftElbowX = leftShoulderX - upperArmLength * 0.3;
        final leftElbowY = shoulderY + upperArmLength;
        final leftHandX = leftElbowX - lowerArmLength * 0.15;
        final leftHandY = leftElbowY + lowerArmLength;
        _drawRoundedLimb(canvas, Offset(leftShoulderX, shoulderY + 8), Offset(leftElbowX, leftElbowY), armWidth, fillPaint, outlinePaint);
        _drawRoundedLimb(canvas, Offset(leftElbowX, leftElbowY), Offset(leftHandX, leftHandY), armWidth * 0.85, fillPaint, outlinePaint);
        break;

      case 'rightArm':
        final rightShoulderX = cx + shoulderWidth;
        final rightElbowX = rightShoulderX + upperArmLength * 0.3;
        final rightElbowY = shoulderY + upperArmLength;
        final rightHandX = rightElbowX + lowerArmLength * 0.15;
        final rightHandY = rightElbowY + lowerArmLength;
        _drawRoundedLimb(canvas, Offset(rightShoulderX, shoulderY + 8), Offset(rightElbowX, rightElbowY), armWidth, fillPaint, outlinePaint);
        _drawRoundedLimb(canvas, Offset(rightElbowX, rightElbowY), Offset(rightHandX, rightHandY), armWidth * 0.85, fillPaint, outlinePaint);
        break;

      case 'leftLeg':
        final leftLegX = cx - hipWidth;
        final leftKneeY = hipY + upperLegLength;
        final leftFootY = leftKneeY + lowerLegLength;
        _drawRoundedLimb(canvas, Offset(leftLegX, hipY), Offset(leftLegX - 2, leftKneeY), legWidth, fillPaint, outlinePaint);
        _drawRoundedLimb(canvas, Offset(leftLegX - 2, leftKneeY), Offset(leftLegX - 2, leftFootY), legWidth * 0.85, fillPaint, outlinePaint);
        break;

      case 'rightLeg':
        final rightLegX = cx + hipWidth;
        final rightKneeY = hipY + upperLegLength;
        final rightFootY = rightKneeY + lowerLegLength;
        _drawRoundedLimb(canvas, Offset(rightLegX, hipY), Offset(rightLegX + 2, rightKneeY), legWidth, fillPaint, outlinePaint);
        _drawRoundedLimb(canvas, Offset(rightLegX + 2, rightKneeY), Offset(rightLegX + 2, rightFootY), legWidth * 0.85, fillPaint, outlinePaint);
        break;
    }
  }

  void _drawRoundedLimb(Canvas canvas, Offset start, Offset end, double width, Paint fillPaint, Paint outlinePaint) {
    final limbPaint = Paint()
      ..color = fillPaint.color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, limbPaint);

    final outlineStroke = Paint()
      ..color = outlinePaint.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final perpX = -dy / length * (width / 2);
    final perpY = dx / length * (width / 2);

    final path = Path();
    path.addArc(Rect.fromCircle(center: start, radius: width / 2), atan2(-perpY, -perpX), pi);
    path.lineTo(end.dx + perpX, end.dy + perpY);
    path.addArc(Rect.fromCircle(center: end, radius: width / 2), atan2(perpY, perpX), pi);
    path.lineTo(start.dx - perpX, start.dy - perpY);
    path.close();
    canvas.drawPath(path, outlineStroke);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(points[0], width / 2, paint..style = PaintingStyle.fill);
    } else {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomCharacterPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.isRunning != isRunning;
  }
}

/// 마을 토지
class VillageLand extends StatefulWidget {
  final String characterName;
  final List<DrawingStroke> characterStrokes;

  const VillageLand({
    super.key,
    required this.characterName,
    required this.characterStrokes,
  });

  @override
  State<VillageLand> createState() => _VillageLandState();
}

class _VillageLandState extends State<VillageLand>
    with TickerProviderStateMixin {
  double _characterX = 0;
  double _characterY = 0;
  double _targetX = 0;
  double _targetY = 0;

  AnimationController? _moveController;
  Animation<double>? _moveAnimation;
  late AnimationController _walkController;

  double _startX = 0;
  double _startY = 0;

  bool _isMoving = false;
  bool _isRunning = false;
  bool _facingRight = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _moveController?.dispose();
    _walkController.dispose();
    super.dispose();
  }

  void _moveCharacter(Offset target, {bool running = false}) {
    setState(() {
      _isMoving = true;
      _isRunning = running;
      _facingRight = target.dx > _characterX + 30;
    });

    _startX = _characterX;
    _startY = _characterY;
    _targetX = target.dx - 30;
    _targetY = target.dy - 70;

    final distance = sqrt(
      pow(_targetX - _startX, 2) + pow(_targetY - _startY, 2),
    );

    final speed = running ? 500.0 : 180.0;
    final duration = Duration(milliseconds: (distance / speed * 1000).toInt());

    _moveController?.dispose();
    _moveController = AnimationController(duration: duration, vsync: this);

    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moveController!, curve: Curves.linear),
    );

    _moveAnimation!.addListener(() {
      setState(() {
        final progress = _moveAnimation!.value;
        _characterX = _startX + (_targetX - _startX) * progress;
        _characterY = _startY + (_targetY - _startY) * progress;
      });
    });

    _moveAnimation!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isMoving = false;
          _isRunning = false;
        });
        _walkController.stop();
        _walkController.reset();
      }
    });

    // 걷기 애니메이션
    _walkController.duration = Duration(milliseconds: running ? 250 : 500);
    _walkController.repeat();

    _moveController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      _characterX = size.width / 2 - 30;
      _characterY = size.height / 2 - 70;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          _moveCharacter(details.localPosition, running: false);
        },
        onLongPressStart: (details) {
          _moveCharacter(details.localPosition, running: true);
        },
        child: Stack(
          children: [
            Container(color: Colors.black),

            Positioned(
              left: _characterX,
              top: _characterY,
              child: Column(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                    child: AnimatedBuilder(
                      animation: _walkController,
                      builder: (context, child) {
                        // 사용자가 그린 캐릭터가 있으면 항상 사용 (애니메이션 포함)
                        if (widget.characterStrokes.isNotEmpty) {
                          return CustomPaint(
                            size: const Size(60, 100),
                            painter: CustomCharacterPainter(
                              strokes: widget.characterStrokes,
                              animationValue: _walkController.value,
                              isMoving: _isMoving,
                              isRunning: _isRunning,
                            ),
                          );
                        }
                        // 그림이 없으면 졸라맨
                        return CustomPaint(
                          size: const Size(60, 100),
                          painter: StickmanPainter(
                            animationValue: _walkController.value,
                            isMoving: _isMoving,
                            isRunning: _isRunning,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.characterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
