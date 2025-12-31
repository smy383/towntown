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
        builder: (context) => VillageLand(characterName: name),
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

/// 마을 토지
class VillageLand extends StatefulWidget {
  final String characterName;

  const VillageLand({super.key, required this.characterName});

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
