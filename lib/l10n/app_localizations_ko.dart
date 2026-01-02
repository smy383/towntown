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

  @override
  String get navHome => '홈';

  @override
  String get navSearch => '검색';

  @override
  String get navTown => '마을';

  @override
  String get navSettings => '설정';

  @override
  String get feedTitle => '피드';

  @override
  String get feedEmpty => '아직 소식이 없습니다';

  @override
  String get feedEmptyDesc => '마을에 가입하면 소식이 여기에 표시됩니다';

  @override
  String get searchTitle => '검색';

  @override
  String get searchHint => '마을이나 사용자 검색';

  @override
  String get searchVillages => '마을';

  @override
  String get searchUsers => '사용자';

  @override
  String get searchEmpty => '검색 결과가 없습니다';

  @override
  String get townTitle => '마을';

  @override
  String get townEmpty => '마을이 없습니다';

  @override
  String get townEmptyDesc => '마을을 만들거나 다른 마을에 가입해보세요';

  @override
  String get createVillageTitle => '마을 만들기';

  @override
  String get villageNameHint => '마을 이름을 입력하세요';

  @override
  String get villageNameLabel => '마을 이름';

  @override
  String get villageCreating => '마을을 생성하고 있습니다...';

  @override
  String get villageCreated => '마을이 생성되었습니다!';

  @override
  String get villageCreateButton => '마을 만들기';

  @override
  String get villageLocation => '위치';

  @override
  String get villageAlreadyExists => '이미 마을을 보유하고 있습니다';

  @override
  String get findingLocation => '위치를 찾고 있습니다...';

  @override
  String get yourVillageLocation => '당신의 마을 위치';

  @override
  String get allVillages => '모든 마을';

  @override
  String get population => '인구';

  @override
  String get noVillageYet => '아직 마을이 없습니다';

  @override
  String get createFirstVillage => '첫 번째 마을을 만들어보세요!';

  @override
  String get villageFull => '마을 정원이 가득 찼습니다';

  @override
  String get villagePrivate => '비공개 마을입니다';

  @override
  String get villageNotFound => '마을을 찾을 수 없습니다';

  @override
  String villageCapacity(Object current, Object max) {
    return '$current/$max명';
  }

  @override
  String get chatTitle => '채팅';

  @override
  String get loginRequired => '로그인이 필요합니다';

  @override
  String get noChatRooms => '채팅방이 없습니다';

  @override
  String get noMessages => '메시지가 없습니다';

  @override
  String get messageHint => '메시지를 입력하세요';

  @override
  String get leaveChat => '채팅방 나가기';

  @override
  String get leaveChatConfirm => '정말 채팅방을 나가시겠습니까?';

  @override
  String get leave => '나가기';

  @override
  String get membershipRequest => '주민 신청';

  @override
  String get membershipPending => '신청 중';

  @override
  String get membershipMember => '주민';

  @override
  String get membershipOwner => '이장';

  @override
  String get membershipRequestSent => '주민 신청을 보냈습니다';

  @override
  String get membershipAlreadyMember => '이미 주민입니다';

  @override
  String get membershipAlreadyRequested => '이미 신청 중입니다';

  @override
  String get membershipApprove => '승인';

  @override
  String get membershipReject => '거절';

  @override
  String get membershipRemove => '제명';

  @override
  String get membershipLeave => '주민 탈퇴';

  @override
  String get membershipLeaveConfirm => '정말 주민에서 탈퇴하시겠습니까?';

  @override
  String get membershipRequests => '가입 신청';

  @override
  String get membershipNoRequests => '대기 중인 신청이 없습니다';

  @override
  String get membershipApproved => '승인되었습니다';

  @override
  String get membershipRejected => '거절되었습니다';

  @override
  String get members => '주민';

  @override
  String memberCount(Object count) {
    return '주민 $count명';
  }

  @override
  String villageCapacityInfo(Object bonus, Object current, Object max) {
    return '수용 인원: $current/$max명 (주민 +$bonus)';
  }

  @override
  String get inviteMember => '주민 초대';

  @override
  String get invitationSent => '초대를 보냈습니다';

  @override
  String get invitationAlreadySent => '이미 초대를 보냈습니다';

  @override
  String get invitationReceived => '주민 초대가 왔습니다';

  @override
  String invitationFrom(Object name, Object village) {
    return '$name님이 $village 주민으로 초대했습니다';
  }

  @override
  String get invitationAccept => '수락';

  @override
  String get invitationDecline => '거절';

  @override
  String get invitationCancel => '초대 취소';

  @override
  String get invitationAccepted => '초대를 수락했습니다';

  @override
  String get invitationDeclined => '초대를 거절했습니다';

  @override
  String get invitationCancelled => '초대를 취소했습니다';

  @override
  String get myInvitations => '받은 초대';

  @override
  String get sentInvitations => '보낸 초대';

  @override
  String get noInvitations => '받은 초대가 없습니다';

  @override
  String get selectHouseLocation => '집 위치를 선택하세요';

  @override
  String get buildHouseHere => '여기에 집 짓기';

  @override
  String get drawYourHouse => '집을 그려주세요';

  @override
  String get doorGuide => '문 위치';

  @override
  String get completeHouse => '집 완성';

  @override
  String get villageDraft => '미완성';

  @override
  String get chiefHouse => '이장의 집';

  @override
  String get houseBuilding => '집을 짓는 중...';

  @override
  String get houseSaved => '집이 완성되었습니다!';

  @override
  String get villagePublished => '마을이 공개되었습니다!';

  @override
  String get tapToPlaceHouse => '화면을 탭해서 집 위치를 정하세요';

  @override
  String get changeLocation => '위치 변경';

  @override
  String get updateAvailable => '업데이트 가능';

  @override
  String get updateRequired => '업데이트 필요';

  @override
  String updateAvailableMessage(Object version) {
    return '새 버전($version)이 있습니다. 업데이트 하시겠습니까?';
  }

  @override
  String updateRequiredMessage(Object version) {
    return '앱을 계속 사용하려면 새 버전($version)으로 업데이트해야 합니다.';
  }

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get newVersion => '새 버전';

  @override
  String get currentVersion => '현재 버전';
}
