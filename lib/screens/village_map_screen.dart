import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/village_model.dart';
import 'house_design_screen.dart';

/// 마을 전체 맵에서 집 위치를 선택하는 화면
class VillageMapScreen extends StatefulWidget {
  final VillageModel village;

  const VillageMapScreen({
    super.key,
    required this.village,
  });

  @override
  State<VillageMapScreen> createState() => _VillageMapScreenState();
}

class _VillageMapScreenState extends State<VillageMapScreen> {
  // 월드 크기
  static const double worldWidth = 2000;
  static const double worldHeight = 2000;

  // 집 크기 (월드 좌표 기준)
  static const double houseWidth = 300;
  static const double houseHeight = 240;

  // 선택된 집 위치 (월드 좌표)
  Offset? _selectedPosition;

  // 맵 뷰 크기
  double _mapViewWidth = 0;
  double _mapViewHeight = 0;

  // 스케일 (월드 → 화면)
  double get _scale => _mapViewWidth / worldWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.selectHouseLocation,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 안내 텍스트
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.tapToPlaceHouse,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 맵 뷰
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 맵 뷰 크기 계산 (정사각형, 화면에 맞게)
                  final size = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth - 32
                      : constraints.maxHeight - 32;

                  _mapViewWidth = size;
                  _mapViewHeight = size;

                  return GestureDetector(
                    onTapDown: (details) {
                      _onMapTap(details.localPosition);
                    },
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _MapPainter(
                            scale: _scale,
                            selectedPosition: _selectedPosition,
                            houseWidth: houseWidth,
                            houseHeight: houseHeight,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 하단 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 위치 변경 버튼 (위치가 선택된 경우)
                if (_selectedPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${l10n.villageLocation}: (${_selectedPosition!.dx.toInt()}, ${_selectedPosition!.dy.toInt()})',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),

                // 집 짓기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedPosition != null ? _onBuildHouse : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.cyanAccent,
                      side: BorderSide(
                        color: _selectedPosition != null
                            ? Colors.cyanAccent
                            : Colors.grey,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      l10n.buildHouseHere,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTap(Offset localPosition) {
    // 화면 좌표 → 월드 좌표
    final worldX = (localPosition.dx / _scale).clamp(
      houseWidth / 2,
      worldWidth - houseWidth / 2,
    );
    final worldY = (localPosition.dy / _scale).clamp(
      houseHeight / 2,
      worldHeight - houseHeight / 2,
    );

    setState(() {
      _selectedPosition = Offset(worldX, worldY);
    });
  }

  void _onBuildHouse() {
    if (_selectedPosition == null) return;

    // HouseDesignScreen으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HouseDesignScreen(
          village: widget.village,
          houseX: _selectedPosition!.dx,
          houseY: _selectedPosition!.dy,
        ),
      ),
    );
  }
}

/// 맵 그리기 Painter
class _MapPainter extends CustomPainter {
  final double scale;
  final Offset? selectedPosition;
  final double houseWidth;
  final double houseHeight;

  _MapPainter({
    required this.scale,
    this.selectedPosition,
    required this.houseWidth,
    required this.houseHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그리드
    _drawGrid(canvas, size);

    // 중앙 표시
    _drawCenter(canvas, size);

    // 선택된 위치에 집 가이드 표시
    if (selectedPosition != null) {
      _drawHouseGuide(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // 100px 단위 그리드 (월드 기준)
    final gridSpacing = 100 * scale;
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 500px 단위 그리드 (더 진하게)
    paint.color = Colors.grey.withValues(alpha: 0.4);
    final majorSpacing = 500 * scale;
    for (double x = 0; x <= size.width; x += majorSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y <= size.height; y += majorSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawCenter(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 중앙 십자 표시
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX + 20, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 20),
      Offset(centerX, centerY + 20),
      paint,
    );
  }

  void _drawHouseGuide(Canvas canvas, Size size) {
    if (selectedPosition == null) return;

    // 월드 좌표 → 화면 좌표
    final screenX = selectedPosition!.dx * scale;
    final screenY = selectedPosition!.dy * scale;
    final screenWidth = houseWidth * scale;
    final screenHeight = houseHeight * scale;

    // 집 위치 사각형 (중앙 기준)
    final rect = Rect.fromCenter(
      center: Offset(screenX, screenY),
      width: screenWidth,
      height: screenHeight,
    );

    // 반투명 흰색 배경
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // 글로우 효과
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.scale != scale;
  }
}
