import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/village_model.dart';

/// 통합 검색 결과 타입
enum SearchResultType { village, user }

/// 통합 검색 결과 아이템
class SearchResult {
  final SearchResultType type;
  final dynamic data; // VillageModel or UserModel

  SearchResult({required this.type, required this.data});

  /// 마을인 경우
  VillageModel? get village => type == SearchResultType.village ? data as VillageModel : null;

  /// 사용자인 경우
  UserModel? get user => type == SearchResultType.user ? data as UserModel : null;
}

/// 검색 서비스
class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 통합 검색 (마을 + 사용자)
  Future<List<SearchResult>> search(String query, {String? excludeUserId}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.trim().toLowerCase();
    final results = <SearchResult>[];

    // 마을 검색과 사용자 검색을 병렬로 실행
    final futures = await Future.wait([
      _searchVillages(normalizedQuery),
      _searchUsers(normalizedQuery, excludeUserId: excludeUserId),
    ]);

    // 마을 결과 추가
    for (final village in futures[0] as List<VillageModel>) {
      results.add(SearchResult(type: SearchResultType.village, data: village));
    }

    // 사용자 결과 추가
    for (final user in futures[1] as List<UserModel>) {
      results.add(SearchResult(type: SearchResultType.user, data: user));
    }

    return results;
  }

  /// 마을 검색
  Future<List<VillageModel>> _searchVillages(String query) async {
    try {
      // Firestore는 LIKE 검색을 지원하지 않으므로 prefix 검색 사용
      // 한글의 경우 전체 데이터를 가져와서 필터링
      final snapshot = await _firestore
          .collection('villages')
          .where('isPublic', isEqualTo: true)
          .limit(50)
          .get();

      final villages = snapshot.docs
          .map((doc) => VillageModel.fromFirestore(doc))
          .where((village) => village.name.toLowerCase().contains(query))
          .take(10)
          .toList();

      return villages;
    } catch (e) {
      return [];
    }
  }

  /// 사용자 검색 (캐릭터 이름으로)
  Future<List<UserModel>> _searchUsers(String query, {String? excludeUserId}) async {
    try {
      // 캐릭터가 있는 사용자만 검색
      final snapshot = await _firestore
          .collection('users')
          .limit(50)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            // 본인 제외
            if (excludeUserId != null && user.id == excludeUserId) {
              return false;
            }
            // 캐릭터가 있는 사용자만
            if (!user.hasCharacter) {
              return false;
            }
            // 캐릭터 이름으로 검색
            return user.characterName!.toLowerCase().contains(query);
          })
          .take(10)
          .toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  /// 마을만 검색
  Future<List<VillageModel>> searchVillages(String query) async {
    if (query.trim().isEmpty) return [];
    return _searchVillages(query.trim().toLowerCase());
  }

  /// 사용자만 검색
  Future<List<UserModel>> searchUsers(String query, {String? excludeUserId}) async {
    if (query.trim().isEmpty) return [];
    return _searchUsers(query.trim().toLowerCase(), excludeUserId: excludeUserId);
  }
}
