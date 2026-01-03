import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'town_screen.dart';
import 'settings_screen.dart';
import 'create_village_screen.dart';
import 'my_village_screen.dart';
import 'notifications_screen.dart';
import '../providers/auth_provider.dart';
import '../services/village_service.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  AnimationController? _flickerController;
  Animation<double>? _flickerAnimation;
  bool _isAnimating = false;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Color> _tabColors = [
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
  ];

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const TownScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 2),
    ]).animate(_flickerController!);

    _flickerController!.addListener(() {
      if (mounted) setState(() {});
    });

    // 알림 개수 로드
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    final count = await _notificationService.getUnreadCount(userId);
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  @override
  void dispose() {
    _flickerController?.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _isAnimating = true;
      });
      _flickerController?.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _isAnimating = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildNeonLogo(
          _isAnimating && _flickerAnimation != null
              ? _flickerAnimation!.value
              : 1.0,
        ),
        centerTitle: true,
        actions: _buildActions(context),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  isSelected: _currentIndex == 0,
                  activeColor: Colors.cyanAccent,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search,
                  isSelected: _currentIndex == 1,
                  activeColor: Colors.yellowAccent,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.location_city_outlined,
                  selectedIcon: Icons.location_city,
                  isSelected: _currentIndex == 2,
                  activeColor: Colors.purpleAccent,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  isSelected: _currentIndex == 3,
                  activeColor: Colors.blueAccent,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonLogo(double opacity) {
    final townColor = _tabColors[_currentIndex];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'NEON',
            style: TextStyle(
              color: Colors.purpleAccent[100],
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.purpleAccent.withOpacity(0.8),
                  blurRadius: 10,
                ),
                Shadow(
                  color: Colors.purpleAccent.withOpacity(0.6),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Colors.purpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'TOWN',
            style: TextStyle(
              color: townColor.withOpacity(opacity),
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: townColor.withOpacity(0.8 * opacity),
                  blurRadius: 10,
                ),
                Shadow(
                  color: townColor.withOpacity(0.6 * opacity),
                  blurRadius: 20,
                ),
                Shadow(
                  color: townColor.withOpacity(0.4 * opacity),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreateVillagePressed(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    // 이미 마을이 있는지 확인
    final villageService = VillageService();
    final hasVillage = await villageService.hasVillage(userId);

    if (!mounted) return;

    if (hasVillage) {
      // 이미 마을이 있으면 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.villageAlreadyExists)),
      );
    } else {
      // 마을이 없으면 생성 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateVillageScreen(),
        ),
      );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // 마을 탭인 경우 마을 관련 버튼 추가
    if (_currentIndex == 2) {
      actions.addAll([
        IconButton(
          icon: Icon(
            Icons.home,
            color: Colors.redAccent,
            shadows: [
              Shadow(
                color: Colors.redAccent.withOpacity(0.8),
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.redAccent.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyVillageScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.add,
            color: Colors.greenAccent,
            shadows: [
              Shadow(
                color: Colors.greenAccent.withOpacity(0.8),
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.greenAccent.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          onPressed: () => _onCreateVillagePressed(context),
        ),
      ]);
    }

    // 알림 버튼 (모든 탭에서 표시)
    actions.add(
      Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.pinkAccent,
              shadows: [
                Shadow(
                  color: Colors.pinkAccent.withOpacity(0.8),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.pinkAccent.withOpacity(0.5),
                  blurRadius: 16,
                ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // 알림 화면에서 돌아오면 개수 새로고침
              _loadUnreadCount();
            },
          ),
          if (_unreadNotifications > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );

    actions.add(const SizedBox(width: 8));
    return actions;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? activeColor : Colors.grey[600],
          size: 22,
          shadows: isSelected
              ? [
                  Shadow(
                    color: activeColor.withOpacity(0.8),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
