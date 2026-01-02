import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/village_model.dart';
import '../models/house_model.dart';
import '../services/village_service.dart';
import '../providers/auth_provider.dart';
import '../main.dart' as main_app;

/// 집 그리기 화면
class HouseDesignScreen extends StatefulWidget {
  final VillageModel village;
  final double houseX;
  final double houseY;
  final List<DrawingStroke>? existingStrokes;
  final bool isEditMode;

  const HouseDesignScreen({
    super.key,
    required this.village,
    required this.houseX,
    required this.houseY,
    this.existingStrokes,
    this.isEditMode = false,
  });

  @override
  State<HouseDesignScreen> createState() => _HouseDesignScreenState();
}

class _HouseDesignScreenState extends State<HouseDesignScreen> {
  final VillageService _villageService = VillageService();

  late List<DrawingStroke> _strokes;
  List<Offset> _currentStroke = [];
  Color _currentColor = Colors.white;
  double _strokeWidth = 4.0;
  bool _isSaving = false;

  // 캔버스 크기 (그리기용)
  static const double canvasWidth = 300;
  static const double canvasHeight = 240;

  // 문 가이드 위치 (하단 중앙)
  static const double doorGuideWidth = 60;
  static const double doorGuideHeight = 80;
  static const double doorGuideX = (canvasWidth - doorGuideWidth) / 2;
  static const double doorGuideY = canvasHeight - doorGuideHeight;

  @override
  void initState() {
    super.initState();
    if (widget.existingStrokes != null && widget.existingStrokes!.isNotEmpty) {
      _strokes = List.from(widget.existingStrokes!);
    } else {
      _strokes = [];
    }
  }

  // 색상 팔레트
  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.grey,
  ];

  void _onPanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    if (_isInsideCanvas(localPos)) {
      setState(() {
        _currentStroke = [localPos];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final localPos = details.localPosition;
    if (_isInsideCanvas(localPos)) {
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

  bool _isInsideCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dx <= canvasWidth &&
        position.dy >= 0 &&
        position.dy <= canvasHeight;
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

  Future<void> _saveHouse() async {
    if (_isSaving) return;

    final l10n = L10n.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      // 캐릭터 데이터 불러오기
      final userData = await authProvider.getUserData();
      if (!mounted || userData == null) {
        setState(() => _isSaving = false);
        return;
      }

      final userName = userData['characterName'] ?? authProvider.user?.displayName ?? 'Unknown';
      final strokesData = userData['characterStrokes'] as List<dynamic>? ?? [];

      // Map 데이터를 main.dart의 DrawingStroke로 변환
      final characterStrokes = strokesData.map((strokeData) {
        final pointsData = strokeData['points'] as List<dynamic>? ?? [];
        final points = pointsData.map((p) => Offset(
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        )).toList();

        // main.dart의 DrawingStroke 생성
        return main_app.DrawingStroke(
          points: points,
          color: Color(strokeData['color'] as int? ?? 0xFF000000),
          strokeWidth: (strokeData['strokeWidth'] as num?)?.toDouble() ?? 3.0,
        );
      }).toList();

      // HouseModel 생성
      final house = HouseModel(
        id: '', // Firestore에서 자동 생성
        ownerId: userId,
        ownerName: userName,
        x: widget.houseX,
        y: widget.houseY,
        width: HouseModel.renderWidth,
        height: HouseModel.renderHeight,
        doorX: 0.5, // 하단 중앙
        doorY: 1.0,
        doorWidth: 60,
        doorHeight: 80,
        strokes: _strokes,
        isChiefHouse: true,
        createdAt: DateTime.now(),
      );

      // 집 저장 및 마을 상태 변경
      await _villageService.saveChiefHouse(
        villageId: widget.village.id,
        house: house,
      );

      if (mounted) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.villagePublished),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // VillageLand로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => main_app.VillageLand(
              villageId: widget.village.id,
              villageName: widget.village.name,
              characterName: userName,
              characterStrokes: characterStrokes,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.drawYourHouse,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: _undoLastStroke,
            tooltip: '되돌리기',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _colors.map((color) {
                  final isSelected = _currentColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _currentColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white30,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 브러시 크기
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              children: [
                const Text('굵기', style: TextStyle(color: Colors.white54)),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 20,
                    activeColor: Colors.cyanAccent,
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

          // 캔버스
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: canvasWidth,
                      height: canvasHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          size: const Size(canvasWidth, canvasHeight),
                          painter: HouseCanvasPainter(
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
                  // 문 위치 안내
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.door_front_door, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        l10n.doorGuide,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 완료 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveHouse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.cyanAccent,
                        ),
                      )
                    : Text(
                        l10n.completeHouse,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 집 그리기 캔버스 Painter
class HouseCanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  HouseCanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 문 가이드 그리기 (하단 중앙)
    _drawDoorGuide(canvas, size);

    // 저장된 스트로크 그리기
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }

    // 현재 그리는 스트로크
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _drawDoorGuide(Canvas canvas, Size size) {
    const doorWidth = 60.0;
    const doorHeight = 80.0;
    final doorX = (size.width - doorWidth) / 2;
    final doorY = size.height - doorHeight;

    final rect = Rect.fromLTWH(doorX, doorY, doorWidth, doorHeight);

    // 반투명 오렌지 배경
    final fillPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fillPaint,
    );

    // 점선 테두리
    final borderPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 점선 효과를 위해 Path 사용
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    // 간단히 실선으로 그리기 (점선 효과는 복잡하므로)
    canvas.drawPath(path, borderPaint);

    // "문" 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🚪',
        style: TextStyle(fontSize: 20),
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

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 네온 글로우 효과
    final isBlack = color == Colors.black;
    final glowColor = isBlack ? Colors.white : color;

    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: isBlack ? 0.2 : 0.3)
        ..strokeWidth = width + (i * 6)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 3.0);
      canvas.drawPath(path, glowPaint);
    }

    // 코어 스트로크
    final corePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant HouseCanvasPainter oldDelegate) {
    return true; // 항상 다시 그리기
  }
}
