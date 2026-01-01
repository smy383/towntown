import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n? of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'네온타운'**
  String get appTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In ko, this message translates to:
  /// **'어디로 갈까요?'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'마을을 만들거나 다른 마을에 놀러가보세요'**
  String get homeSubtitle;

  /// No description provided for @createVillage.
  ///
  /// In ko, this message translates to:
  /// **'마을 만들기'**
  String get createVillage;

  /// No description provided for @createVillageDesc.
  ///
  /// In ko, this message translates to:
  /// **'나만의 마을을 만들어보세요'**
  String get createVillageDesc;

  /// No description provided for @exploreVillage.
  ///
  /// In ko, this message translates to:
  /// **'마을 탐험'**
  String get exploreVillage;

  /// No description provided for @exploreVillageDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람들의 마을을 구경해보세요'**
  String get exploreVillageDesc;

  /// No description provided for @myVillage.
  ///
  /// In ko, this message translates to:
  /// **'내 마을'**
  String get myVillage;

  /// No description provided for @myVillageDesc.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 마을로 이동합니다'**
  String get myVillageDesc;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @myInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get myInfo;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃 하시겠습니까?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @comingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비중...'**
  String get comingSoon;

  /// No description provided for @enterName.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get enterName;

  /// No description provided for @createCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 만들기'**
  String get createCharacter;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get languageSystem;

  /// No description provided for @languageSelect.
  ///
  /// In ko, this message translates to:
  /// **'언어 선택'**
  String get languageSelect;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get navSearch;

  /// No description provided for @navTown.
  ///
  /// In ko, this message translates to:
  /// **'마을'**
  String get navTown;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @feedTitle.
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get feedTitle;

  /// No description provided for @feedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 소식이 없습니다'**
  String get feedEmpty;

  /// No description provided for @feedEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'마을에 가입하면 소식이 여기에 표시됩니다'**
  String get feedEmptyDesc;

  /// No description provided for @searchTitle.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'마을이나 사용자 검색'**
  String get searchHint;

  /// No description provided for @searchVillages.
  ///
  /// In ko, this message translates to:
  /// **'마을'**
  String get searchVillages;

  /// No description provided for @searchUsers.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get searchUsers;

  /// No description provided for @searchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get searchEmpty;

  /// No description provided for @townTitle.
  ///
  /// In ko, this message translates to:
  /// **'마을'**
  String get townTitle;

  /// No description provided for @townEmpty.
  ///
  /// In ko, this message translates to:
  /// **'마을이 없습니다'**
  String get townEmpty;

  /// No description provided for @townEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'마을을 만들거나 다른 마을에 가입해보세요'**
  String get townEmptyDesc;

  /// No description provided for @createVillageTitle.
  ///
  /// In ko, this message translates to:
  /// **'마을 만들기'**
  String get createVillageTitle;

  /// No description provided for @villageNameHint.
  ///
  /// In ko, this message translates to:
  /// **'마을 이름을 입력하세요'**
  String get villageNameHint;

  /// No description provided for @villageNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'마을 이름'**
  String get villageNameLabel;

  /// No description provided for @villageCreating.
  ///
  /// In ko, this message translates to:
  /// **'마을을 생성하고 있습니다...'**
  String get villageCreating;

  /// No description provided for @villageCreated.
  ///
  /// In ko, this message translates to:
  /// **'마을이 생성되었습니다!'**
  String get villageCreated;

  /// No description provided for @villageCreateButton.
  ///
  /// In ko, this message translates to:
  /// **'마을 만들기'**
  String get villageCreateButton;

  /// No description provided for @villageLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get villageLocation;

  /// No description provided for @villageAlreadyExists.
  ///
  /// In ko, this message translates to:
  /// **'이미 마을을 보유하고 있습니다'**
  String get villageAlreadyExists;

  /// No description provided for @findingLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾고 있습니다...'**
  String get findingLocation;

  /// No description provided for @yourVillageLocation.
  ///
  /// In ko, this message translates to:
  /// **'당신의 마을 위치'**
  String get yourVillageLocation;

  /// No description provided for @allVillages.
  ///
  /// In ko, this message translates to:
  /// **'모든 마을'**
  String get allVillages;

  /// No description provided for @population.
  ///
  /// In ko, this message translates to:
  /// **'인구'**
  String get population;

  /// No description provided for @noVillageYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 마을이 없습니다'**
  String get noVillageYet;

  /// No description provided for @createFirstVillage.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 마을을 만들어보세요!'**
  String get createFirstVillage;

  /// No description provided for @villageFull.
  ///
  /// In ko, this message translates to:
  /// **'마을 정원이 가득 찼습니다'**
  String get villageFull;

  /// No description provided for @villagePrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개 마을입니다'**
  String get villagePrivate;

  /// No description provided for @villageNotFound.
  ///
  /// In ko, this message translates to:
  /// **'마을을 찾을 수 없습니다'**
  String get villageNotFound;

  /// No description provided for @villageCapacity.
  ///
  /// In ko, this message translates to:
  /// **'{current}/{max}명'**
  String villageCapacity(Object current, Object max);

  /// No description provided for @chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chatTitle;

  /// No description provided for @loginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get loginRequired;

  /// No description provided for @noChatRooms.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 없습니다'**
  String get noChatRooms;

  /// No description provided for @noMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 없습니다'**
  String get noMessages;

  /// No description provided for @messageHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get messageHint;

  /// No description provided for @leaveChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 나가기'**
  String get leaveChat;

  /// No description provided for @leaveChatConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 채팅방을 나가시겠습니까?'**
  String get leaveChatConfirm;

  /// No description provided for @leave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get leave;

  /// No description provided for @membershipRequest.
  ///
  /// In ko, this message translates to:
  /// **'주민 신청'**
  String get membershipRequest;

  /// No description provided for @membershipPending.
  ///
  /// In ko, this message translates to:
  /// **'신청 중'**
  String get membershipPending;

  /// No description provided for @membershipMember.
  ///
  /// In ko, this message translates to:
  /// **'주민'**
  String get membershipMember;

  /// No description provided for @membershipOwner.
  ///
  /// In ko, this message translates to:
  /// **'이장'**
  String get membershipOwner;

  /// No description provided for @membershipRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'주민 신청을 보냈습니다'**
  String get membershipRequestSent;

  /// No description provided for @membershipAlreadyMember.
  ///
  /// In ko, this message translates to:
  /// **'이미 주민입니다'**
  String get membershipAlreadyMember;

  /// No description provided for @membershipAlreadyRequested.
  ///
  /// In ko, this message translates to:
  /// **'이미 신청 중입니다'**
  String get membershipAlreadyRequested;

  /// No description provided for @membershipApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get membershipApprove;

  /// No description provided for @membershipReject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get membershipReject;

  /// No description provided for @membershipRemove.
  ///
  /// In ko, this message translates to:
  /// **'제명'**
  String get membershipRemove;

  /// No description provided for @membershipLeave.
  ///
  /// In ko, this message translates to:
  /// **'주민 탈퇴'**
  String get membershipLeave;

  /// No description provided for @membershipLeaveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 주민에서 탈퇴하시겠습니까?'**
  String get membershipLeaveConfirm;

  /// No description provided for @membershipRequests.
  ///
  /// In ko, this message translates to:
  /// **'가입 신청'**
  String get membershipRequests;

  /// No description provided for @membershipNoRequests.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 신청이 없습니다'**
  String get membershipNoRequests;

  /// No description provided for @membershipApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인되었습니다'**
  String get membershipApproved;

  /// No description provided for @membershipRejected.
  ///
  /// In ko, this message translates to:
  /// **'거절되었습니다'**
  String get membershipRejected;

  /// No description provided for @members.
  ///
  /// In ko, this message translates to:
  /// **'주민'**
  String get members;

  /// No description provided for @memberCount.
  ///
  /// In ko, this message translates to:
  /// **'주민 {count}명'**
  String memberCount(Object count);

  /// No description provided for @villageCapacityInfo.
  ///
  /// In ko, this message translates to:
  /// **'수용 인원: {current}/{max}명 (주민 +{bonus})'**
  String villageCapacityInfo(Object bonus, Object current, Object max);

  /// No description provided for @inviteMember.
  ///
  /// In ko, this message translates to:
  /// **'주민 초대'**
  String get inviteMember;

  /// No description provided for @invitationSent.
  ///
  /// In ko, this message translates to:
  /// **'초대를 보냈습니다'**
  String get invitationSent;

  /// No description provided for @invitationAlreadySent.
  ///
  /// In ko, this message translates to:
  /// **'이미 초대를 보냈습니다'**
  String get invitationAlreadySent;

  /// No description provided for @invitationReceived.
  ///
  /// In ko, this message translates to:
  /// **'주민 초대가 왔습니다'**
  String get invitationReceived;

  /// No description provided for @invitationFrom.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {village} 주민으로 초대했습니다'**
  String invitationFrom(Object name, Object village);

  /// No description provided for @invitationAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get invitationAccept;

  /// No description provided for @invitationDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get invitationDecline;

  /// No description provided for @invitationCancel.
  ///
  /// In ko, this message translates to:
  /// **'초대 취소'**
  String get invitationCancel;

  /// No description provided for @invitationAccepted.
  ///
  /// In ko, this message translates to:
  /// **'초대를 수락했습니다'**
  String get invitationAccepted;

  /// No description provided for @invitationDeclined.
  ///
  /// In ko, this message translates to:
  /// **'초대를 거절했습니다'**
  String get invitationDeclined;

  /// No description provided for @invitationCancelled.
  ///
  /// In ko, this message translates to:
  /// **'초대를 취소했습니다'**
  String get invitationCancelled;

  /// No description provided for @myInvitations.
  ///
  /// In ko, this message translates to:
  /// **'받은 초대'**
  String get myInvitations;

  /// No description provided for @sentInvitations.
  ///
  /// In ko, this message translates to:
  /// **'보낸 초대'**
  String get sentInvitations;

  /// No description provided for @noInvitations.
  ///
  /// In ko, this message translates to:
  /// **'받은 초대가 없습니다'**
  String get noInvitations;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'ja':
      return L10nJa();
    case 'ko':
      return L10nKo();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
