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
