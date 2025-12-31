import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import '../widgets/globe_widget.dart';

class CreateVillageScreen extends StatefulWidget {
  const CreateVillageScreen({super.key});

  @override
  State<CreateVillageScreen> createState() => _CreateVillageScreenState();
}

class _CreateVillageScreenState extends State<CreateVillageScreen>
    with TickerProviderStateMixin {
  final VillageService _villageService = VillageService();
  final TextEditingController _nameController = TextEditingController();

  // 애니메이션 컨트롤러
  late AnimationController _globeScaleController;
  late AnimationController _zoomController;
  late AnimationController _pulseController;
  late Animation<double> _globeScaleAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _pulseAnimation;

  // 상태
  List<VillagePoint> _existingVillages = [];
  VillagePoint? _newVillagePoint;
  int _currentStep = 0; // 0: 로딩, 1: 지구본, 2: 회전, 3: 줌인, 4: 이름입력, 5: 생성중, 6: 완료
  bool _isCreating = false;
  VillageModel? _createdVillage;

  // 회전 목표값
  double? _targetRotationX;
  double? _targetRotationY;

  @override
  void initState() {
    super.initState();

    // 지구본 등장 애니메이션
    _globeScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _globeScaleAnimation = CurvedAnimation(
      parent: _globeScaleController,
      curve: Curves.elasticOut,
    );

    // 줌인 애니메이션
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOutCubic,
    );

    // 펄스 애니메이션 (새 마을 깜빡임)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _startCreationFlow();
  }

  @override
  void dispose() {
    _globeScaleController.dispose();
    _zoomController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startCreationFlow() async {
    // Step 0: 기존 마을 데이터 로드
    setState(() => _currentStep = 0);

    try {
      final positions = await _villageService.getAllVillagePositions();
      _existingVillages = positions
          .map((p) => VillagePoint(x: p['x']!, y: p['y']!))
          .toList();
    } catch (e) {
      _existingVillages = [];
    }

    // 새 마을 위치 미리 계산 (중심에서 랜덤)
    final random = Random();
    final villageCount = _existingVillages.length;
    final maxRadius = (sqrt(villageCount + 1) * 10).toInt().clamp(50, 4500);
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * maxRadius;
    final newX = (5000 + distance * cos(angle)).toInt().clamp(0, 9999);
    final newY = (5000 + distance * sin(angle)).toInt().clamp(0, 9999);

    _newVillagePoint = VillagePoint(x: newX, y: newY, isHighlighted: true);

    // Step 1: 지구본 등장
    setState(() => _currentStep = 1);
    await Future.delayed(const Duration(milliseconds: 300));
    _globeScaleController.forward();

    await Future.delayed(const Duration(seconds: 2));

    // Step 2: 새 마을 위치로 회전
    setState(() {
      _currentStep = 2;
      _targetRotationX = _newVillagePoint!.targetRotationX;
      _targetRotationY = _newVillagePoint!.targetRotationY;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 3: 줌인
    setState(() => _currentStep = 3);
    _zoomController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 4: 이름 입력
    setState(() => _currentStep = 4);
  }

  Future<void> _createVillage() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _currentStep = 5;
      _isCreating = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final village = await _villageService.createVillage(
        userId: userId,
        villageName: _nameController.text.trim(),
      );

      setState(() {
        _createdVillage = village;
        _currentStep = 6;
        _isCreating = false;
      });

      // 2초 후 화면 닫기
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(village);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 지구본
            if (_currentStep >= 1)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _globeScaleAnimation,
                  _zoomAnimation,
                ]),
                builder: (context, child) {
                  final scale = _globeScaleAnimation.value +
                      (_zoomAnimation.value * 2);
                  return Transform.scale(
                    scale: scale.clamp(0.0, 3.0),
                    child: Opacity(
                      opacity: _currentStep == 6 ? 0.3 : 1.0,
                      child: GlobeWidget(
                        villages: _existingVillages,
                        newVillage: _newVillagePoint,
                        autoRotate: _currentStep < 2,
                        enableGesture: false,
                        targetRotationX: _targetRotationX,
                        targetRotationY: _targetRotationY,
                        globeColor: Colors.purpleAccent,
                        dotColor: Colors.cyanAccent,
                        highlightColor: Colors.yellowAccent,
                      ),
                    ),
                  );
                },
              ),

            // 로딩 표시
            if (_currentStep == 0)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.findingLocation,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // 위치 표시 (줌인 후)
            if (_currentStep >= 3 && _newVillagePoint != null)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _currentStep >= 3 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        l10n.yourVillageLocation,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.yellowAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          VillageModel.createSectorId(
                            _newVillagePoint!.x,
                            _newVillagePoint!.y,
                          ),
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 이름 입력 폼
            if (_currentStep == 4)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildNameInputForm(l10n),
              ),

            // 생성 중
            if (_currentStep == 5)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.villageCreating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

            // 생성 완료
            if (_currentStep == 6 && _createdVillage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 80,
                      shadows: [
                        Shadow(
                          color: Colors.greenAccent.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.villageCreated,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _createdVillage!.name,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.greenAccent.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 닫기 버튼
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputForm(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.createVillageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.5),
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              cursorColor: Colors.greenAccent,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: l10n.villageNameHint,
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (_) => _createVillage(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createVillage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.villageCreateButton,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
