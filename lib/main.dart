import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'dart:math';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/village_service.dart';
import 'services/player_service.dart';
import 'widgets/membership_button.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Kakao SDK
  // TODO: Replace with your actual Kakao keys
  KakaoSdk.init(
    nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
    javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_KEY',
  );

  runApp(const TownTownApp());
}

class TownTownApp extends StatelessWidget {
  const TownTownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          title: 'NeonTown',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Show loading screen while checking auth state
            if (auth.status == AuthStatus.initial) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            // Show auth screen if not authenticated
            if (!auth.isAuthenticated) {
              return const AuthScreen();
            }

            // Check if character setup is needed
            return const _AuthenticatedHome();
          },
        ),
        ),
      ),
    );
  }
}

/// 인증된 사용자의 홈 화면 결정
class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome();

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  late Future<bool> _hasCharacterFuture;

  @override
  void initState() {
    super.initState();
    _hasCharacterFuture = context.read<AuthProvider>().hasCharacter();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCharacterFuture,
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        // 에러 발생
        if (snapshot.hasError) {
          return const MainNavigationScreen();
        }

        // 캐릭터가 없으면 생성 화면으로
        final hasCharacter = snapshot.data ?? false;
        if (!hasCharacter) {
          return const CreateCharacterScreen();
        }

        // 캐릭터가 있으면 메인 화면으로
        return const MainNavigationScreen();
      },
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
  final List<DrawingStroke>? existingStrokes; // 수정 모드용
  final bool isEditMode;

  const CharacterDesignScreen({
    super.key,
    required this.characterName,
    this.existingStrokes,
    this.isEditMode = false,
  });

  @override
  State<CharacterDesignScreen> createState() => _CharacterDesignScreenState();
}

class _CharacterDesignScreenState extends State<CharacterDesignScreen> {
  late List<DrawingStroke> _strokes;
  List<Offset> _currentStroke = [];
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    // 수정 모드일 때 기존 그림 불러오기
    if (widget.existingStrokes != null && widget.existingStrokes!.isNotEmpty) {
      _strokes = List.from(widget.existingStrokes!);
    } else {
      _strokes = [];
    }
  }

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
    if (localPos != null && BodyPartRegions.isInsideSilhouette(localPos)) {
      setState(() {
        _currentStroke = [localPos];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    final localPos = _getLocalPosition(details.localPosition, canvasSize);
    if (localPos != null && BodyPartRegions.isInsideSilhouette(localPos)) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
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
                  const SizedBox(height: 8),
                  // 움직임 방향 표시
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.white54, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '움직임 방향',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 완료 / 저장 버튼
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: ElevatedButton(
              onPressed: () async {
                if (widget.isEditMode) {
                  // 수정 모드: strokes 반환
                  Navigator.pop(context, _strokes);
                } else {
                  // 새로 만들기 모드: Firestore에 저장 후 메인 화면으로
                  final authProvider = context.read<AuthProvider>();

                  // DrawingStroke를 Map으로 변환
                  final strokesData = _strokes.map((stroke) => {
                    'points': stroke.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
                    'color': stroke.color.value,
                    'strokeWidth': stroke.strokeWidth,
                  }).toList();

                  // Firestore에 저장
                  await authProvider.saveCharacter(
                    name: widget.characterName,
                    strokes: strokesData,
                  );

                  // 메인 화면으로 이동
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: Text(
                widget.isEditMode ? '저장하기' : '완료',
                style: const TextStyle(fontSize: 16),
              ),
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

    // 네온 효과를 위한 Path 생성
    final path = Path();
    if (points.length == 1) {
      // 점 하나인 경우 원으로 처리
      _drawNeonCircle(canvas, points[0], width / 2, color);
      return;
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 검정색인 경우 글로우를 흰색으로
    final isBlack = color.red < 30 && color.green < 30 && color.blue < 30;
    final glowColor = isBlack ? Colors.white : color;

    // 네온 글로우 효과 (바깥쪽 빛)
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(isBlack ? 0.3 : 0.4)
        ..strokeWidth = width + (i * 8)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 4.0);
      canvas.drawPath(path, glowPaint);
    }

    // 코어 (원래 색상 유지)
    final corePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, corePaint);
  }

  void _drawNeonCircle(Canvas canvas, Offset center, double radius, Color color) {
    final isBlack = color.red < 30 && color.green < 30 && color.blue < 30;
    final glowColor = isBlack ? Colors.white : color;

    // 글로우
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(isBlack ? 0.3 : 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 4.0);
      canvas.drawCircle(center, radius + (i * 4), glowPaint);
    }
    // 코어 (원래 색상 유지)
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    // 현재 그리는 중일 때는 항상 다시 그리기
    return true;
  }
}

/// 하얀색 실루엣 캐릭터 (뼈대 위에 파츠 형태)
class BodyCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 하얀색 실루엣 (90% 투명)
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 회색 외곽선 (파츠 구분용, 약간 투명)
    final outlinePaint = Paint()
      ..color = Colors.grey.shade600.withOpacity(0.3)
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

/// 졸라맨 그리기 (관절 시스템) - 네온 효과
class StickmanPainter extends CustomPainter {
  final double animationValue;
  final bool isMoving;
  final bool isRunning;

  StickmanPainter({
    required this.animationValue,
    required this.isMoving,
    required this.isRunning,
  });

  // 네온 선 그리기
  void _drawNeonLine(Canvas canvas, Offset start, Offset end, double strokeWidth) {
    // 글로우 효과
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = strokeWidth + (i * 4)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 2.0);
      canvas.drawLine(start, end, glowPaint);
    }
    // 코어
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, corePaint);
  }

  // 네온 원 그리기 (머리용)
  void _drawNeonCircle(Canvas canvas, Offset center, double radius) {
    // 글로우 효과
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 3.0);
      canvas.drawCircle(center, radius + (i * 2), glowPaint);
    }
    // 코어
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.0;

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
      _drawFrontView(canvas, size, strokeWidth, cx, headRadius,
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
    _drawNeonCircle(canvas, Offset(headCenter.x, headCenter.y), headRadius);

    // 목 그리기
    _drawNeonLine(
      canvas,
      Offset(shoulder.x, shoulder.y),
      Offset(neckTop.x, neckTop.y),
      strokeWidth,
    );

    // 몸통 그리기
    _drawNeonLine(canvas, Offset(shoulder.x, shoulder.y), Offset(hip.x, hip.y), strokeWidth);

    // 어깨 너비 (양쪽으로 팔이 나옴)
    final shoulderWidth = size.width * 0.18;
    final leftShoulderJoint = Joint(shoulder.x - shoulderWidth, shoulder.y);
    final rightShoulderJoint = Joint(shoulder.x + shoulderWidth, shoulder.y);

    // === 어깨선 그리기 ===
    _drawNeonLine(
      canvas,
      Offset(leftShoulderJoint.x, leftShoulderJoint.y),
      Offset(rightShoulderJoint.x, rightShoulderJoint.y),
      strokeWidth,
    );

    // === 왼쪽 팔 ===
    final leftArmSwing = isMoving ? pose['leftShoulder']! : 0.0;
    final leftUpperArmAngle = pi / 2 - leftArmSwing;
    final leftElbowPos = leftShoulderJoint.rotate(leftUpperArmAngle, upperArmLength);

    // 팔꿈치: 항상 앞쪽(-방향)으로만 굽혀짐
    final leftElbowBend = isMoving ? pose['leftElbow']! : 0.3;
    final leftHandAngle = leftUpperArmAngle - leftElbowBend;
    final leftHand = leftElbowPos.rotate(leftHandAngle, lowerArmLength);

    _drawNeonLine(
      canvas,
      Offset(leftShoulderJoint.x, leftShoulderJoint.y),
      Offset(leftElbowPos.x, leftElbowPos.y),
      strokeWidth,
    );
    _drawNeonLine(
      canvas,
      Offset(leftElbowPos.x, leftElbowPos.y),
      Offset(leftHand.x, leftHand.y),
      strokeWidth,
    );

    // === 오른쪽 팔 ===
    final rightArmSwing = isMoving ? pose['rightShoulder']! : 0.0;
    final rightUpperArmAngle = pi / 2 - rightArmSwing;
    final rightElbowPos = rightShoulderJoint.rotate(rightUpperArmAngle, upperArmLength);

    // 팔꿈치: 항상 앞쪽(-방향)으로만 굽혀짐
    final rightElbowBend = isMoving ? pose['rightElbow']! : 0.3;
    final rightHandAngle = rightUpperArmAngle - rightElbowBend;
    final rightHand = rightElbowPos.rotate(rightHandAngle, lowerArmLength);

    _drawNeonLine(
      canvas,
      Offset(rightShoulderJoint.x, rightShoulderJoint.y),
      Offset(rightElbowPos.x, rightElbowPos.y),
      strokeWidth,
    );
    _drawNeonLine(
      canvas,
      Offset(rightElbowPos.x, rightElbowPos.y),
      Offset(rightHand.x, rightHand.y),
      strokeWidth,
    );

    // === 왼쪽 다리 ===
    final leftHipAngle = pi / 2 + (isMoving ? pose['leftHip']! : 0);
    final leftKneePos = hip.rotate(leftHipAngle, upperLegLength);

    // 무릎은 허벅지 방향 기준으로 항상 뒤쪽(양수)으로만 굽힘
    final leftKneeBend = isMoving ? pose['leftKnee']!.abs() : 0.0;
    final leftFootAngle = leftHipAngle + leftKneeBend;
    final leftFoot = leftKneePos.rotate(leftFootAngle, lowerLegLength);

    _drawNeonLine(canvas, Offset(hip.x, hip.y), Offset(leftKneePos.x, leftKneePos.y), strokeWidth);
    _drawNeonLine(canvas, Offset(leftKneePos.x, leftKneePos.y), Offset(leftFoot.x, leftFoot.y), strokeWidth);

    // === 오른쪽 다리 ===
    final rightHipAngle = pi / 2 + (isMoving ? pose['rightHip']! : 0);
    final rightKneePos = hip.rotate(rightHipAngle, upperLegLength);

    final rightKneeBend = isMoving ? pose['rightKnee']!.abs() : 0.0;
    final rightFootAngle = rightHipAngle + rightKneeBend;
    final rightFoot = rightKneePos.rotate(rightFootAngle, lowerLegLength);

    _drawNeonLine(canvas, Offset(hip.x, hip.y), Offset(rightKneePos.x, rightKneePos.y), strokeWidth);
    _drawNeonLine(canvas, Offset(rightKneePos.x, rightKneePos.y), Offset(rightFoot.x, rightFoot.y), strokeWidth);
  }

  // 정면 뷰 그리기
  void _drawFrontView(
    Canvas canvas,
    Size size,
    double strokeWidth,
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
    _drawNeonCircle(canvas, Offset(cx, headY), headRadius);

    // 목
    final neckTop = headY + headRadius;
    final shoulderY = neckTop + neckLength;
    _drawNeonLine(canvas, Offset(cx, neckTop), Offset(cx, shoulderY), strokeWidth);

    // 몸통
    final hipY = shoulderY + torsoLength;
    _drawNeonLine(canvas, Offset(cx, shoulderY), Offset(cx, hipY), strokeWidth);

    // 어깨선
    final shoulderWidth = size.width * 0.25;
    _drawNeonLine(
      canvas,
      Offset(cx - shoulderWidth, shoulderY),
      Offset(cx + shoulderWidth, shoulderY),
      strokeWidth,
    );

    // 왼쪽 팔 (정면에서 볼 때 약간 벌어짐)
    final leftShoulderX = cx - shoulderWidth;
    final leftElbowX = leftShoulderX - upperArmLength * 0.3;
    final leftElbowY = shoulderY + upperArmLength * 0.9;
    final leftHandX = leftElbowX - lowerArmLength * 0.2;
    final leftHandY = leftElbowY + lowerArmLength * 0.95;
    _drawNeonLine(canvas, Offset(leftShoulderX, shoulderY), Offset(leftElbowX, leftElbowY), strokeWidth);
    _drawNeonLine(canvas, Offset(leftElbowX, leftElbowY), Offset(leftHandX, leftHandY), strokeWidth);

    // 오른쪽 팔
    final rightShoulderX = cx + shoulderWidth;
    final rightElbowX = rightShoulderX + upperArmLength * 0.3;
    final rightElbowY = shoulderY + upperArmLength * 0.9;
    final rightHandX = rightElbowX + lowerArmLength * 0.2;
    final rightHandY = rightElbowY + lowerArmLength * 0.95;
    _drawNeonLine(canvas, Offset(rightShoulderX, shoulderY), Offset(rightElbowX, rightElbowY), strokeWidth);
    _drawNeonLine(canvas, Offset(rightElbowX, rightElbowY), Offset(rightHandX, rightHandY), strokeWidth);

    // 왼쪽 다리
    final hipWidth = size.width * 0.1;
    final leftKneeX = cx - hipWidth - upperLegLength * 0.15;
    final leftKneeY = hipY + upperLegLength * 0.95;
    final leftFootX = leftKneeX;
    final leftFootY = leftKneeY + lowerLegLength;
    _drawNeonLine(canvas, Offset(cx - hipWidth, hipY), Offset(leftKneeX, leftKneeY), strokeWidth);
    _drawNeonLine(canvas, Offset(leftKneeX, leftKneeY), Offset(leftFootX, leftFootY), strokeWidth);

    // 오른쪽 다리
    final rightKneeX = cx + hipWidth + upperLegLength * 0.15;
    final rightKneeY = hipY + upperLegLength * 0.95;
    final rightFootX = rightKneeX;
    final rightFootY = rightKneeY + lowerLegLength;
    _drawNeonLine(canvas, Offset(cx + hipWidth, hipY), Offset(rightKneeX, rightKneeY), strokeWidth);
    _drawNeonLine(canvas, Offset(rightKneeX, rightKneeY), Offset(rightFootX, rightFootY), strokeWidth);
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

  // 실루엣 치수 계산
  static double get cx => canvasSize.width / 2;
  static double get headRadius => canvasSize.width * 0.20;
  static double get headY => canvasSize.height * 0.13;
  static double get neckTop => headY + headRadius;
  static double get shoulderY => neckTop + canvasSize.height * 0.02;
  static double get torsoHeight => canvasSize.height * 0.28;
  static double get torsoWidth => canvasSize.width * 0.38;
  static double get hipY => shoulderY + torsoHeight;
  static double get shoulderWidth => canvasSize.width * 0.22;
  static double get armWidth => canvasSize.width * 0.10;
  static double get upperArmLength => canvasSize.height * 0.14;
  static double get lowerArmLength => canvasSize.height * 0.13;
  static double get hipWidth => canvasSize.width * 0.08;
  static double get legWidth => canvasSize.width * 0.12;
  static double get upperLegLength => canvasSize.height * 0.17;
  static double get lowerLegLength => canvasSize.height * 0.16;

  // 점이 실루엣 안에 있는지 확인
  static bool isInsideSilhouette(Offset point) {
    return _isInsideHead(point) ||
           _isInsideTorso(point) ||
           _isInsideLeftArm(point) ||
           _isInsideRightArm(point) ||
           _isInsideLeftLeg(point) ||
           _isInsideRightLeg(point);
  }

  // 머리 (원)
  static bool _isInsideHead(Offset point) {
    final center = Offset(cx, headY);
    return (point - center).distance <= headRadius;
  }

  // 몸통 (둥근 사각형)
  static bool _isInsideTorso(Offset point) {
    final rect = Rect.fromCenter(
      center: Offset(cx, shoulderY + torsoHeight / 2),
      width: torsoWidth,
      height: torsoHeight,
    );
    // 간단하게 사각형으로 체크 (둥근 모서리는 무시)
    return rect.contains(point);
  }

  // 캡슐(둥근 끝 팔다리) 안에 있는지 체크
  static bool _isInsideCapsule(Offset point, Offset start, Offset end, double width) {
    final radius = width / 2;

    // 시작점 원 안에 있는지
    if ((point - start).distance <= radius) return true;
    // 끝점 원 안에 있는지
    if ((point - end).distance <= radius) return true;

    // 선분과의 거리 체크
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) return false;

    // 점을 선분에 투영
    var t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSq;
    t = t.clamp(0.0, 1.0);

    final projX = start.dx + t * dx;
    final projY = start.dy + t * dy;
    final distance = (point - Offset(projX, projY)).distance;

    return distance <= radius;
  }

  // 왼쪽 팔
  static bool _isInsideLeftArm(Offset point) {
    final leftShoulderX = cx - shoulderWidth;
    final leftElbowX = leftShoulderX - upperArmLength * 0.3;
    final leftElbowY = shoulderY + upperArmLength;
    final leftHandX = leftElbowX - lowerArmLength * 0.15;
    final leftHandY = leftElbowY + lowerArmLength;

    final shoulderPos = Offset(leftShoulderX, shoulderY + 8);
    final elbowPos = Offset(leftElbowX, leftElbowY);
    final handPos = Offset(leftHandX, leftHandY);

    return _isInsideCapsule(point, shoulderPos, elbowPos, armWidth) ||
           _isInsideCapsule(point, elbowPos, handPos, armWidth * 0.85);
  }

  // 오른쪽 팔
  static bool _isInsideRightArm(Offset point) {
    final rightShoulderX = cx + shoulderWidth;
    final rightElbowX = rightShoulderX + upperArmLength * 0.3;
    final rightElbowY = shoulderY + upperArmLength;
    final rightHandX = rightElbowX + lowerArmLength * 0.15;
    final rightHandY = rightElbowY + lowerArmLength;

    final shoulderPos = Offset(rightShoulderX, shoulderY + 8);
    final elbowPos = Offset(rightElbowX, rightElbowY);
    final handPos = Offset(rightHandX, rightHandY);

    return _isInsideCapsule(point, shoulderPos, elbowPos, armWidth) ||
           _isInsideCapsule(point, elbowPos, handPos, armWidth * 0.85);
  }

  // 왼쪽 다리
  static bool _isInsideLeftLeg(Offset point) {
    final leftLegX = cx - hipWidth;
    final leftKneeY = hipY + upperLegLength;
    final leftFootY = leftKneeY + lowerLegLength;

    final hipPos = Offset(leftLegX, hipY);
    final kneePos = Offset(leftLegX - 2, leftKneeY);
    final footPos = Offset(leftLegX - 2, leftFootY);

    return _isInsideCapsule(point, hipPos, kneePos, legWidth) ||
           _isInsideCapsule(point, kneePos, footPos, legWidth * 0.85);
  }

  // 오른쪽 다리
  static bool _isInsideRightLeg(Offset point) {
    final rightLegX = cx + hipWidth;
    final rightKneeY = hipY + upperLegLength;
    final rightFootY = rightKneeY + lowerLegLength;

    final hipPos = Offset(rightLegX, hipY);
    final kneePos = Offset(rightLegX + 2, rightKneeY);
    final footPos = Offset(rightLegX + 2, rightFootY);

    return _isInsideCapsule(point, hipPos, kneePos, legWidth) ||
           _isInsideCapsule(point, kneePos, footPos, legWidth * 0.85);
  }

  // 각 부위의 바운딩 박스 (애니메이션용)
  static Rect get head => Rect.fromCircle(center: Offset(cx, headY), radius: headRadius + 5);

  static Rect get torso => Rect.fromCenter(
    center: Offset(cx, shoulderY + torsoHeight / 2),
    width: torsoWidth + 10,
    height: torsoHeight + 10,
  );

  static Rect get leftArm => Rect.fromLTRB(0, torso.top - 10, cx - shoulderWidth + 30, torso.bottom + 40);
  static Rect get rightArm => Rect.fromLTRB(cx + shoulderWidth - 30, torso.top - 10, canvasSize.width, torso.bottom + 40);
  static Rect get leftLeg => Rect.fromLTRB(0, torso.bottom - 20, cx, canvasSize.height);
  static Rect get rightLeg => Rect.fromLTRB(cx, torso.bottom - 20, canvasSize.width, canvasSize.height);

  // 점이 어느 부위에 속하는지 판단
  static String? getBodyPart(Offset point) {
    if (_isInsideHead(point)) return 'head';
    if (_isInsideLeftArm(point)) return 'leftArm';
    if (_isInsideRightArm(point)) return 'rightArm';
    if (_isInsideTorso(point)) return 'torso';
    if (_isInsideLeftLeg(point)) return 'leftLeg';
    if (_isInsideRightLeg(point)) return 'rightLeg';
    return null; // 실루엣 밖
  }

  // 각 부위의 피벗 포인트 (회전 중심)
  static Offset getPivot(String part) {
    switch (part) {
      case 'head':
        return Offset(cx, headY + headRadius); // 목 위치
      case 'leftArm':
        return Offset(cx - shoulderWidth, shoulderY + 8); // 왼쪽 어깨
      case 'rightArm':
        return Offset(cx + shoulderWidth, shoulderY + 8); // 오른쪽 어깨
      case 'leftLeg':
        return Offset(cx - hipWidth, hipY); // 왼쪽 골반
      case 'rightLeg':
        return Offset(cx + hipWidth, hipY); // 오른쪽 골반
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

    // 실루엣은 그리지 않음 - 사용자 그림만 표시

    // 해당 부위에 속하는 스트로크 그리기
    for (final stroke in strokes) {
      final partPoints = <Offset>[];
      for (final point in stroke.points) {
        final bodyPart = BodyPartRegions.getBodyPart(point);
        if (bodyPart == part) {
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

    // 네온 효과를 위한 Path 생성
    final path = Path();
    if (points.length == 1) {
      _drawNeonCircle(canvas, points[0], width / 2, color);
      return;
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 검정색인 경우 글로우를 흰색으로
    final isBlack = color.red < 30 && color.green < 30 && color.blue < 30;
    final glowColor = isBlack ? Colors.white : color;

    // 네온 글로우 효과 (바깥쪽 빛)
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(isBlack ? 0.3 : 0.4)
        ..strokeWidth = width + (i * 8)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 4.0);
      canvas.drawPath(path, glowPaint);
    }

    // 코어 (원래 색상 유지)
    final corePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, corePaint);
  }

  void _drawNeonCircle(Canvas canvas, Offset center, double radius, Color color) {
    final isBlack = color.red < 30 && color.green < 30 && color.blue < 30;
    final glowColor = isBlack ? Colors.white : color;

    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(isBlack ? 0.3 : 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 4.0);
      canvas.drawCircle(center, radius + (i * 4), glowPaint);
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
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
  final String? villageId;
  final String characterName;
  final List<DrawingStroke> characterStrokes;

  const VillageLand({
    super.key,
    this.villageId,
    required this.characterName,
    required this.characterStrokes,
  });

  @override
  State<VillageLand> createState() => _VillageLandState();
}

class _VillageLandState extends State<VillageLand>
    with TickerProviderStateMixin {
  // 월드 크기 (화면보다 큼)
  static const double worldWidth = 2000;
  static const double worldHeight = 2000;

  final VillageService _villageService = VillageService();
  final PlayerService _playerService = PlayerService();

  // 멀티플레이어 관련
  StreamSubscription<List<PlayerState>>? _playersSubscription;
  List<PlayerState> _otherPlayers = [];
  Timer? _positionUpdateTimer;
  Timer? _heartbeatTimer;
  String? _myUid;

  // 캐릭터의 월드 좌표
  double _worldX = worldWidth / 2;
  double _worldY = worldHeight / 2;
  double _targetWorldX = 0;
  double _targetWorldY = 0;

  AnimationController? _moveController;
  Animation<double>? _moveAnimation;
  late AnimationController _walkController;

  double _startWorldX = 0;
  double _startWorldY = 0;

  bool _isMoving = false;
  bool _isRunning = false;
  bool _facingRight = true;
  bool _initialized = false;

  // 달리기 모드 (손가락 따라가기)
  bool _isRunningMode = false;
  Ticker? _runTicker;
  Duration _lastTickTime = Duration.zero;

  // 화면 크기
  late Size _screenSize;

  // 캐릭터 수정 관련
  bool _showEditButton = false;
  late String _characterName;
  late List<DrawingStroke> _characterStrokes;
  DateTime? _lastNameChangeDate;

  // 채팅/말풍선 관련
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  String? _speechBubbleText;
  DateTime? _speechBubbleTime;
  bool _isSpeechBubblePinned = false; // 말풍선 고정 여부

  @override
  void initState() {
    super.initState();
    _characterName = widget.characterName;
    _characterStrokes = List.from(widget.characterStrokes);
    _walkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 멀티플레이어 초기화
    _initMultiplayer();
  }

  /// 멀티플레이어 시스템 초기화
  Future<void> _initMultiplayer() async {
    final villageId = widget.villageId;
    if (villageId == null) return;

    final authProvider = context.read<AuthProvider>();
    _myUid = authProvider.user?.uid;
    if (_myUid == null) return;

    // 캐릭터 스트로크를 Map으로 변환
    final strokesData = _characterStrokes.map((stroke) => {
      'points': stroke.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': stroke.color.value,
      'strokeWidth': stroke.strokeWidth,
    }).toList();

    // 마을에 입장
    await _playerService.enterVillage(
      villageId: villageId,
      uid: _myUid!,
      characterName: _characterName,
      characterStrokes: strokesData,
      initialX: _worldX,
      initialY: _worldY,
    );

    // 다른 플레이어 구독
    _playersSubscription = _playerService.playersStream(villageId).listen((players) {
      if (mounted) {
        setState(() {
          _otherPlayers = players.where((p) => p.uid != _myUid).toList();
        });
      }
    });

    // 위치 업데이트 타이머 (100ms 간격)
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _syncPositionToFirestore();
    });

    // Heartbeat 타이머 (10초 간격)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (villageId != null && _myUid != null) {
        _playerService.heartbeat(villageId: villageId, uid: _myUid!);
      }
    });
  }

  /// 내 위치를 Firestore에 동기화
  Future<void> _syncPositionToFirestore() async {
    final villageId = widget.villageId;
    if (villageId == null || _myUid == null) return;

    await _playerService.updatePosition(
      villageId: villageId,
      uid: _myUid!,
      x: _worldX,
      y: _worldY,
      facingRight: _facingRight,
      isMoving: _isMoving,
      isRunning: _isRunning,
    );
  }

  // 카메라 오프셋 계산 (월드 좌표 -> 화면 좌표 변환용)
  Offset get _cameraOffset {
    // 캐릭터를 화면 중앙에 두기 위한 카메라 위치
    double cameraX = _worldX - _screenSize.width / 2;
    double cameraY = _worldY - _screenSize.height / 2;

    // 카메라가 월드 경계를 벗어나지 않도록 클램프
    cameraX = cameraX.clamp(0, worldWidth - _screenSize.width);
    cameraY = cameraY.clamp(0, worldHeight - _screenSize.height);

    return Offset(cameraX, cameraY);
  }

  // 캐릭터의 화면 좌표
  Offset get _characterScreenPos {
    final camera = _cameraOffset;
    return Offset(_worldX - camera.dx - 30, _worldY - camera.dy - 50);
  }

  // 화면 좌표 -> 월드 좌표 변환
  Offset _screenToWorld(Offset screenPos) {
    final camera = _cameraOffset;
    return Offset(screenPos.dx + camera.dx, screenPos.dy + camera.dy);
  }

  @override
  void dispose() {
    // 멀티플레이어 정리
    _playersSubscription?.cancel();
    _positionUpdateTimer?.cancel();
    _heartbeatTimer?.cancel();

    _moveController?.dispose();
    _walkController.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _runTicker?.dispose();
    super.dispose();
  }

  /// 마을 퇴장
  Future<void> _leaveVillage() async {
    final villageId = widget.villageId;
    if (villageId == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    // 플레이어 상태 삭제
    await _playerService.leaveVillage(
      villageId: villageId,
      uid: userId,
    );

    // 마을 인원 감소
    await _villageService.leaveVillage(
      villageId: villageId,
      userId: userId,
    );
  }

  /// 나가기 버튼 처리
  Future<bool> _onWillPop() async {
    await _leaveVillage();
    return true;
  }

  // 채팅 메시지 전송
  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final wasPinned = _isSpeechBubblePinned;

    setState(() {
      _speechBubbleText = text;
      _speechBubbleTime = DateTime.now();
      // 이미 고정 상태였으면 계속 고정 유지
      _isSpeechBubblePinned = wasPinned;
    });
    _chatController.clear();

    // Firestore에 채팅 동기화
    _syncChatToFirestore(text);

    // 포커스 유지 (엔터 키 전송 후에도 계속 입력 가능)
    _chatFocusNode.requestFocus();

    // 고정 상태가 아닐 때만 5초 후 사라짐
    if (!wasPinned) {
      _scheduleHideBubble();
    }
  }

  /// 채팅을 Firestore에 동기화
  Future<void> _syncChatToFirestore(String message) async {
    final villageId = widget.villageId;
    if (villageId == null || _myUid == null) return;

    await _playerService.sendChat(
      villageId: villageId,
      uid: _myUid!,
      message: message,
    );
  }

  /// 채팅 삭제를 Firestore에 동기화
  Future<void> _clearChatFromFirestore() async {
    final villageId = widget.villageId;
    if (villageId == null || _myUid == null) return;

    await _playerService.clearChat(
      villageId: villageId,
      uid: _myUid!,
    );
  }

  // 말풍선 자동 숨김 예약
  void _scheduleHideBubble() {
    final currentTime = _speechBubbleTime;
    Future.delayed(const Duration(seconds: 5), () {
      // 고정 상태면 사라지지 않음
      if (_isSpeechBubblePinned) return;
      // 시간이 변경됐으면 (새 메시지) 무시
      if (_speechBubbleTime != currentTime) return;

      setState(() {
        _speechBubbleText = null;
        _speechBubbleTime = null;
      });

      // Firestore에서도 삭제
      _clearChatFromFirestore();
    });
  }

  // 말풍선 고정 토글
  void _togglePinBubble() {
    if (_speechBubbleText == null) return;

    setState(() {
      _isSpeechBubblePinned = !_isSpeechBubblePinned;
    });

    // 고정 해제하면 5초 후 사라짐
    if (!_isSpeechBubblePinned) {
      _speechBubbleTime = DateTime.now();
      _scheduleHideBubble();
    }
  }

  // 캐릭터 탭 시 수정 버튼 표시
  void _onCharacterTap() {
    setState(() {
      _showEditButton = !_showEditButton;
    });
  }

  // 수정 버튼 숨기기
  void _hideEditButton() {
    if (_showEditButton) {
      setState(() {
        _showEditButton = false;
      });
    }
  }

  // 이름 변경 가능 여부 확인 (한달에 한번)
  bool _canChangeName() {
    if (_lastNameChangeDate == null) return true;
    final difference = DateTime.now().difference(_lastNameChangeDate!);
    return difference.inDays >= 30;
  }

  // 이름 변경까지 남은 일수
  int _daysUntilNameChange() {
    if (_lastNameChangeDate == null) return 0;
    final difference = DateTime.now().difference(_lastNameChangeDate!);
    final remaining = 30 - difference.inDays;
    return remaining > 0 ? remaining : 0;
  }

  // 수정 옵션 다이얼로그
  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '캐릭터 수정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // 외형 수정 버튼
                ListTile(
                  leading: const Icon(Icons.brush, color: Colors.blue),
                  title: const Text('외형 수정', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('캐릭터를 다시 그립니다', style: TextStyle(color: Colors.white54)),
                  onTap: () {
                    Navigator.pop(context);
                    _editCharacterAppearance();
                  },
                ),

                // 이름 변경 버튼
                ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: _canChangeName() ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    '이름 변경',
                    style: TextStyle(
                      color: _canChangeName() ? Colors.white : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    _canChangeName()
                        ? '이름을 변경합니다 (월 1회)'
                        : '${_daysUntilNameChange()}일 후 변경 가능',
                    style: TextStyle(
                      color: _canChangeName() ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  onTap: _canChangeName()
                      ? () {
                          Navigator.pop(context);
                          _showNameChangeDialog();
                        }
                      : null,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // 외형 수정
  void _editCharacterAppearance() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterDesignScreen(
          characterName: _characterName,
          existingStrokes: _characterStrokes,
          isEditMode: true,
        ),
      ),
    );

    // 결과가 있으면 캐릭터 업데이트
    if (result != null && result is List<DrawingStroke>) {
      setState(() {
        _characterStrokes = result;
        _showEditButton = false;
      });
    }
  }

  // 이름 변경 다이얼로그
  void _showNameChangeDialog() {
    final controller = TextEditingController(text: _characterName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('이름 변경', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새로운 이름을 입력하세요.\n(한달에 한번만 변경 가능)',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '새 이름',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != _characterName) {
                  setState(() {
                    _characterName = newName;
                    _lastNameChangeDate = DateTime.now();
                    _showEditButton = false;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('이름이 변경되었습니다')),
                  );
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  void _moveCharacter(Offset screenTarget, {bool running = false}) {
    // 화면 좌표를 월드 좌표로 변환
    final worldTarget = _screenToWorld(screenTarget);

    // 월드 경계 내로 제한
    final clampedX = worldTarget.dx.clamp(30.0, worldWidth - 30.0);
    final clampedY = worldTarget.dy.clamp(50.0, worldHeight - 50.0);

    setState(() {
      _isMoving = true;
      _isRunning = running;
      _facingRight = clampedX > _worldX;
    });

    _startWorldX = _worldX;
    _startWorldY = _worldY;
    _targetWorldX = clampedX;
    _targetWorldY = clampedY;

    final distance = sqrt(
      pow(_targetWorldX - _startWorldX, 2) + pow(_targetWorldY - _startWorldY, 2),
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
        _worldX = _startWorldX + (_targetWorldX - _startWorldX) * progress;
        _worldY = _startWorldY + (_targetWorldY - _startWorldY) * progress;
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

  // 달리기 시작 (손가락 따라가기 모드)
  void _startRunning(Offset screenTarget) {
    // 기존 이동 애니메이션 취소
    _moveController?.stop();

    final worldTarget = _screenToWorld(screenTarget);
    _targetWorldX = worldTarget.dx.clamp(30.0, worldWidth - 30.0);
    _targetWorldY = worldTarget.dy.clamp(50.0, worldHeight - 50.0);

    setState(() {
      _isRunningMode = true;
      _isMoving = true;
      _isRunning = true;
      _facingRight = _targetWorldX > _worldX;
    });

    _walkController.duration = const Duration(milliseconds: 250);
    _walkController.repeat();

    // Ticker 시작
    _runTicker?.dispose();
    _runTicker = createTicker(_onRunTick);
    _lastTickTime = Duration.zero;
    _runTicker!.start();
  }

  // 매 프레임 달리기 업데이트
  void _onRunTick(Duration elapsed) {
    final dt = (elapsed - _lastTickTime).inMilliseconds / 1000.0;
    _lastTickTime = elapsed;

    // 목표 방향으로 이동
    final dx = _targetWorldX - _worldX;
    final dy = _targetWorldY - _worldY;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 10) {
      // 목표에 가까우면 이동 멈춤 (달리기 모드는 유지)
      if (_isMoving) {
        setState(() {
          _isMoving = false;
        });
        _walkController.stop();
        _walkController.reset();
      }
      return;
    }

    // 다시 움직이기 시작할 때 애니메이션 재개
    if (!_isMoving) {
      setState(() {
        _isMoving = true;
      });
      _walkController.duration = const Duration(milliseconds: 250);
      _walkController.repeat();
    }

    const speed = 400.0; // 달리기 속도 (픽셀/초)
    final moveDistance = speed * dt;
    final ratio = (moveDistance / distance).clamp(0.0, 1.0);

    setState(() {
      _worldX += dx * ratio;
      _worldY += dy * ratio;

      // 방향 전환
      if (dx.abs() > 5) {
        _facingRight = dx > 0;
      }
    });
  }

  // 달리기 목표 업데이트 (손가락 이동 시)
  void _updateRunTarget(Offset screenTarget) {
    if (!_isRunningMode) return;

    final worldTarget = _screenToWorld(screenTarget);
    _targetWorldX = worldTarget.dx.clamp(30.0, worldWidth - 30.0);
    _targetWorldY = worldTarget.dy.clamp(50.0, worldHeight - 50.0);

    // 방향 전환
    final dx = _targetWorldX - _worldX;
    if (dx.abs() > 5) {
      setState(() {
        _facingRight = dx > 0;
      });
    }
  }

  // 달리기 종료
  void _stopRunning() {
    _runTicker?.stop();
    _runTicker?.dispose();
    _runTicker = null;
    _isRunningMode = false;

    setState(() {
      _isMoving = false;
      _isRunning = false;
    });

    _walkController.stop();
    _walkController.reset();
  }

  /// 다른 플레이어 위젯 빌드
  Widget _buildOtherPlayer(PlayerState player, Offset camera) {
    // 플레이어의 화면 좌표 계산
    final screenX = player.x - camera.dx - 30;
    final screenY = player.y - camera.dy - 50;

    // 캐릭터 스트로크 변환
    final strokes = player.characterStrokes.map((strokeData) {
      final pointsData = strokeData['points'] as List<dynamic>? ?? [];
      final points = pointsData.map((p) => Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      )).toList();

      return DrawingStroke(
        points: points,
        color: Color(strokeData['color'] as int? ?? 0xFF000000),
        strokeWidth: (strokeData['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      );
    }).toList();

    return Positioned(
      left: screenX,
      top: screenY,
      child: Column(
        children: [
          // 다른 플레이어 캐릭터
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(player.facingRight ? 1.0 : -1.0, 1.0),
            child: strokes.isNotEmpty
                ? CustomPaint(
                    size: const Size(60, 100),
                    painter: CustomCharacterPainter(
                      strokes: strokes,
                      animationValue: 0,
                      isMoving: player.isMoving,
                      isRunning: player.isRunning,
                    ),
                  )
                : CustomPaint(
                    size: const Size(60, 100),
                    painter: StickmanPainter(
                      animationValue: 0,
                      isMoving: player.isMoving,
                      isRunning: player.isRunning,
                    ),
                  ),
          ),
          // 이름
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.characterName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 말풍선 (있으면)
          if (player.chatMessage != null && player.chatMessage!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                player.chatMessage!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    if (!_initialized) {
      _initialized = true;
    }

    final charScreenPos = _characterScreenPos;
    final camera = _cameraOffset;

    // 캐릭터 영역 (말풍선, 수정 버튼 포함)
    final bubbleHeight = _speechBubbleText != null ? 60.0 : 0.0;
    final editButtonHeight = _showEditButton ? 40.0 : 0.0;
    final characterRect = Rect.fromLTWH(
      charScreenPos.dx - 10,
      charScreenPos.dy - bubbleHeight - editButtonHeight,
      80,
      130 + bubbleHeight + editButtonHeight,
    );

    // 채팅창 영역
    final chatInputRect = Rect.fromLTWH(
      0,
      _screenSize.height - 80,
      _screenSize.width,
      80,
    );

    // 나가기 버튼 영역 (좌상단)
    final safeTop = MediaQuery.of(context).padding.top;
    final exitButtonRect = Rect.fromLTWH(
      16,
      safeTop + 16,
      48,
      48,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveVillage();
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 월드 배경 (그리드로 이동 확인용)
            Positioned(
              left: -camera.dx,
              top: -camera.dy,
              child: CustomPaint(
                size: const Size(worldWidth, worldHeight),
                painter: WorldGridPainter(),
              ),
            ),

            // 배경 터치 영역 (캐릭터 이동용) - 캐릭터보다 아래에 위치
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final tapPos = details.localPosition;
                  // 캐릭터 영역은 캐릭터 자체의 GestureDetector가 처리
                  _hideEditButton();
                  if (_isRunningMode) {
                    _stopRunning();
                  }
                  _moveCharacter(tapPos, running: false);
                },
                onLongPressStart: (details) {
                  final tapPos = details.localPosition;
                  _hideEditButton();
                  _startRunning(tapPos);
                },
                onLongPressMoveUpdate: (details) {
                  final tapPos = details.localPosition;
                  _updateRunTarget(tapPos);
                },
                onLongPressEnd: (_) {
                  _stopRunning();
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // 다른 플레이어들
            ..._otherPlayers.map((player) => _buildOtherPlayer(player, camera)),

            // 내 캐릭터 + 이름
            Positioned(
              left: charScreenPos.dx,
              top: charScreenPos.dy,
              child: Column(
                children: [
                  // 캐릭터
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {}, // 이벤트 흡수
                    onTap: () {
                      _onCharacterTap();
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _walkController,
                        builder: (context, child) {
                          if (_characterStrokes.isNotEmpty) {
                            return CustomPaint(
                              size: const Size(60, 100),
                              painter: CustomCharacterPainter(
                                strokes: _characterStrokes,
                                animationValue: _walkController.value,
                                isMoving: _isMoving,
                                isRunning: _isRunning,
                              ),
                            );
                          }
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _characterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 수정 버튼 (캐릭터 위)
            if (_showEditButton)
              Positioned(
                left: charScreenPos.dx - 5,
                top: charScreenPos.dy - 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {},
                  onTap: _showEditOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '수정',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 말풍선 (캐릭터 위, 중앙 정렬)
            if (_speechBubbleText != null)
              Positioned(
                left: charScreenPos.dx + 30, // 캐릭터 중앙
                top: charScreenPos.dy - 10, // 캐릭터 바로 위
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.0), // 중앙 정렬 + 위로 확장
                  child: GestureDetector(
                    onTap: _togglePinBubble,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 200),
                          decoration: BoxDecoration(
                            color: _isSpeechBubblePinned ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: _isSpeechBubblePinned
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _speechBubbleText!,
                                style: TextStyle(
                                  color: _isSpeechBubblePinned ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isSpeechBubblePinned)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(16, 8),
                          painter: SpeechBubbleTailPainter(
                            isPinned: _isSpeechBubblePinned,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 나가기 버튼 (좌상단)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await _leaveVillage();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // 주민 상태/신청 버튼 (우상단)
            if (widget.villageId != null)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 16,
                child: MembershipButton(
                  villageId: widget.villageId!,
                ),
              ),

            // 채팅 입력창 (하단)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: ListenableBuilder(
                  listenable: _chatController,
                  builder: (context, child) {
                    final remaining = 50 - _chatController.text.length;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            focusNode: _chatFocusNode,
                            maxLength: 50,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: '메시지를 입력하세요...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              counterText: '', // 글자수 카운터 숨김
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _sendChat(),
                          ),
                        ),
                        // 남은 글자 수 표시
                        if (_chatController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '$remaining',
                              style: TextStyle(
                                color: remaining <= 5
                                    ? Colors.red
                                    : remaining <= 15
                                        ? Colors.orange
                                        : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _sendChat,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 월드 그리드 (이동 확인용)
class WorldGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final majorGridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const gridSize = 100.0;

    // 그리드 라인 그리기
    for (double x = 0; x <= size.width; x += gridSize) {
      final paint = (x % 500 == 0) ? majorGridPaint : gridPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      final paint = (y % 500 == 0) ? majorGridPaint : gridPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 월드 경계선
    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borderPaint);

    // 중앙 마커
    final centerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 말풍선 꼬리
class SpeechBubbleTailPainter extends CustomPainter {
  final bool isPinned;

  SpeechBubbleTailPainter({this.isPinned = false});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = isPinned ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);

    // 고정 상태일 때 테두리
    if (isPinned) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeechBubbleTailPainter oldDelegate) =>
      oldDelegate.isPinned != isPinned;
}
