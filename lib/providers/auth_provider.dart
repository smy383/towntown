import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _needsCharacterSetup = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get needsCharacterSetup => _needsCharacterSetup;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ===== Google Sign In =====
  Future<bool> signInWithGoogle() async {
    return _signIn(() => _authService.signInWithGoogle());
  }

  // ===== Apple Sign In =====
  Future<bool> signInWithApple() async {
    return _signIn(() => _authService.signInWithApple());
  }

  // ===== Kakao Sign In =====
  Future<bool> signInWithKakao() async {
    return _signIn(() => _authService.signInWithKakao());
  }

  // ===== Common Sign In Logic =====
  Future<bool> _signIn(Future<UserCredential?> Function() signInMethod) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await signInMethod();
      if (result != null) {
        _needsCharacterSetup = _authService.needsCharacterSetup;
        return true;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ===== Update Character Name =====
  Future<void> updateCharacterName(String name) async {
    await _authService.updateCharacterName(name);
    _needsCharacterSetup = false;
    notifyListeners();
  }

  // ===== Save Character (Name + Strokes) =====
  Future<void> saveCharacter({
    required String name,
    required List<Map<String, dynamic>> strokes,
  }) async {
    await _authService.saveCharacter(name: name, strokes: strokes);
    _needsCharacterSetup = false;
    notifyListeners();
  }

  // ===== Get User Data =====
  Future<Map<String, dynamic>?> getUserData() async {
    return await _authService.getUserData();
  }

  // ===== Check if user has character =====
  Future<bool> hasCharacter() async {
    return await _authService.hasCharacter();
  }

  // ===== Sign Out =====
  Future<void> signOut() async {
    await _authService.signOut();
    _needsCharacterSetup = false;
  }

  // ===== Clear Error =====
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ===== Error Message Helper =====
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-disabled':
          return '이 계정은 비활성화되었습니다.';
        case 'user-not-found':
          return '사용자를 찾을 수 없습니다.';
        case 'network-request-failed':
          return '네트워크 연결을 확인해주세요.';
        case 'too-many-requests':
          return '잠시 후 다시 시도해주세요.';
        default:
          return '로그인에 실패했습니다. (${error.code})';
      }
    }
    return '로그인에 실패했습니다.';
  }
}
