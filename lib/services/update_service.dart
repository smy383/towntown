import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 앱 업데이트 정보
class AppUpdateInfo {
  final String latestVersion;
  final String minRequiredVersion;
  final String? updateUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.minRequiredVersion,
    this.updateUrl,
    this.releaseNotes,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> data) {
    return AppUpdateInfo(
      latestVersion: data['latestVersion'] ?? '1.0.0',
      minRequiredVersion: data['minRequiredVersion'] ?? '1.0.0',
      updateUrl: data['updateUrl'],
      releaseNotes: data['releaseNotes'],
      forceUpdate: data['forceUpdate'] ?? false,
    );
  }
}

/// 업데이트 체크 결과
enum UpdateStatus {
  upToDate,        // 최신 버전
  updateAvailable, // 업데이트 가능 (선택적)
  updateRequired,  // 업데이트 필수
}

/// 업데이트 서비스
class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 앱 버전 가져오기
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting package info: $e');
      return '0.0.0';
    }
  }

  /// 플랫폼별 문서 ID
  String _getPlatformDocId() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  /// Firestore에서 최신 버전 정보 가져오기
  Future<AppUpdateInfo?> getLatestVersionInfo() async {
    try {
      final docId = _getPlatformDocId();
      final doc = await _firestore.collection('app_config').doc(docId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return AppUpdateInfo.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching version info: $e');
      return null;
    }
  }

  /// 버전 비교 (semver)
  /// 반환값: -1 (v1 < v2), 0 (같음), 1 (v1 > v2)
  int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 길이 맞추기
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// 업데이트 상태 확인
  Future<({UpdateStatus status, AppUpdateInfo? info})> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final updateInfo = await getLatestVersionInfo();

      if (updateInfo == null) {
        return (status: UpdateStatus.upToDate, info: null);
      }

      // 최소 필수 버전보다 낮으면 강제 업데이트
      if (compareVersions(currentVersion, updateInfo.minRequiredVersion) < 0) {
        return (status: UpdateStatus.updateRequired, info: updateInfo);
      }

      // 최신 버전보다 낮으면 선택적 업데이트
      if (compareVersions(currentVersion, updateInfo.latestVersion) < 0) {
        // forceUpdate 플래그가 있으면 강제
        if (updateInfo.forceUpdate) {
          return (status: UpdateStatus.updateRequired, info: updateInfo);
        }
        return (status: UpdateStatus.updateAvailable, info: updateInfo);
      }

      return (status: UpdateStatus.upToDate, info: updateInfo);
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return (status: UpdateStatus.upToDate, info: null);
    }
  }

  /// 앱 스토어 URL 가져오기
  String getStoreUrl() {
    if (kIsWeb) {
      return 'https://neontown.web.app';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'https://play.google.com/store/apps/details?id=com.neontown.app';
      case TargetPlatform.iOS:
        return 'https://apps.apple.com/app/neontown/id000000000'; // 실제 앱 ID로 변경 필요
      default:
        return 'https://neontown.web.app';
    }
  }
}
