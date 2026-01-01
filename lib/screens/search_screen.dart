import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/search_service.dart';
import '../services/village_service.dart';
import '../services/chat_service.dart';
import '../models/village_model.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;

  List<SearchResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _searchService.search(
        query,
        excludeUserId: _myUid,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.yellowAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.yellowAccent,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.yellowAccent,
                    shadows: [
                      Shadow(
                        color: Colors.yellowAccent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(L10n l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellowAccent),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        message: l10n.searchHint,
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: l10n.searchEmpty,
      );
    }

    // 마을과 사용자 분리
    final villages = _results.where((r) => r.type == SearchResultType.village).toList();
    final users = _results.where((r) => r.type == SearchResultType.user).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 마을 섹션
        if (villages.isNotEmpty) ...[
          _buildSectionHeader(l10n.searchVillages, Icons.location_city, Colors.cyanAccent),
          ...villages.map((r) => _VillageResultTile(
            village: r.village!,
            onTap: () => _onVillageTap(r.village!),
          )),
          const SizedBox(height: 16),
        ],

        // 사용자 섹션
        if (users.isNotEmpty) ...[
          _buildSectionHeader(l10n.searchUsers, Icons.person, Colors.pinkAccent),
          ...users.map((r) => _UserResultTile(
            user: r.user!,
            onTap: () => _onUserTap(r.user!),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _onVillageTap(VillageModel village) async {
    final l10n = L10n.of(context)!;

    // 마을 입장 시도
    final villageService = VillageService();
    final result = await villageService.enterVillage(
      villageId: village.id,
      userId: _myUid ?? '',
    );

    if (!mounted) return;

    switch (result) {
      case VillageEntryResult.success:
      case VillageEntryResult.alreadyInside:
        // VillageLand로 이동 (main.dart에 있음)
        Navigator.pushNamed(
          context,
          '/village',
          arguments: village,
        );
        break;
      case VillageEntryResult.full:
        _showSnackBar(l10n.villageFull, Colors.redAccent);
        break;
      case VillageEntryResult.private:
        _showSnackBar(l10n.villagePrivate, Colors.orangeAccent);
        break;
      case VillageEntryResult.notFound:
        _showSnackBar(l10n.villageNotFound, Colors.redAccent);
        break;
    }
  }

  void _onUserTap(UserModel user) async {
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

    // 1:1 채팅방 생성 또는 기존 채팅방 열기
    final chatService = ChatService();
    final room = await chatService.getOrCreateDirectChat(
      myUid: _myUid ?? '',
      myName: myName,
      otherUid: user.id,
      otherName: user.characterName ?? 'Unknown',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(room: room),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 마을 검색 결과 타일
class _VillageResultTile extends StatelessWidget {
  final VillageModel village;
  final VoidCallback onTap;

  const _VillageResultTile({
    required this.village,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.location_city,
            color: Colors.cyanAccent,
            size: 22,
          ),
        ),
        title: Text(
          village.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          l10n.villageCapacity(village.population, village.maxPopulation),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        trailing: village.isFull
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FULL',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                size: 16,
              ),
        onTap: onTap,
      ),
    );
  }
}

/// 사용자 검색 결과 타일
class _UserResultTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserResultTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.pinkAccent.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pinkAccent.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.pinkAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.pinkAccent,
            size: 22,
          ),
        ),
        title: Text(
          user.characterName ?? 'Unknown',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.pinkAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.pinkAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Chat',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
