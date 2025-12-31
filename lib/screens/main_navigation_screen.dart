import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'town_screen.dart';
import 'settings_screen.dart';

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

  final List<Color> _tabColors = [
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
  ];

  final List<Widget> _screens = const [
    FeedScreen(),
    SearchScreen(),
    TownScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 1),
    ]).animate(_flickerController!);
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
        title: _flickerAnimation != null
            ? AnimatedBuilder(
                animation: _flickerAnimation!,
                builder: (context, child) {
                  final opacity = _isAnimating ? _flickerAnimation!.value : 1.0;
                  return _buildNeonLogo(opacity);
                },
              )
            : _buildNeonLogo(1.0),
        centerTitle: true,
        actions: _currentIndex == 2 ? _buildTownActions(context) : null,
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

  List<Widget> _buildTownActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.home,
          color: Colors.orange,
          shadows: [
            Shadow(
              color: Colors.orange.withOpacity(0.6),
              blurRadius: 8,
            ),
          ],
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('준비중...')),
          );
        },
      ),
      IconButton(
        icon: Icon(
          Icons.add_circle,
          color: Colors.blue,
          shadows: [
            Shadow(
              color: Colors.blue.withOpacity(0.6),
              blurRadius: 8,
            ),
          ],
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('준비중...')),
          );
        },
      ),
      const SizedBox(width: 8),
    ];
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
