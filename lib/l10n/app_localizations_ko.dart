// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '네온타운';

  @override
  String get homeWelcome => '어디로 갈까요?';

  @override
  String get homeSubtitle => '마을을 만들거나 다른 마을에 놀러가보세요';

  @override
  String get createVillage => '마을 만들기';

  @override
  String get createVillageDesc => '나만의 마을을 만들어보세요';

  @override
  String get exploreVillage => '마을 탐험';

  @override
  String get exploreVillageDesc => '다른 사람들의 마을을 구경해보세요';

  @override
  String get myVillage => '내 마을';

  @override
  String get myVillageDesc => '내가 만든 마을로 이동합니다';

  @override
  String get settings => '설정';

  @override
  String get myInfo => '내 정보';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '정말 로그아웃 하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get comingSoon => '준비중...';

  @override
  String get enterName => '이름을 입력해주세요';

  @override
  String get createCharacter => '캐릭터 만들기';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageSelect => '언어 선택';
}
