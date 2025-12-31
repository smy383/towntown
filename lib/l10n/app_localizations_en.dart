// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NeonTown';

  @override
  String get homeWelcome => 'Where to go?';

  @override
  String get homeSubtitle => 'Create your own village or visit others';

  @override
  String get createVillage => 'Create Village';

  @override
  String get createVillageDesc => 'Build your own village';

  @override
  String get exploreVillage => 'Explore';

  @override
  String get exploreVillageDesc => 'Visit other people\'s villages';

  @override
  String get myVillage => 'My Village';

  @override
  String get myVillageDesc => 'Go to your villages';

  @override
  String get settings => 'Settings';

  @override
  String get myInfo => 'My Info';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get comingSoon => 'Coming soon...';

  @override
  String get enterName => 'Please enter your name';

  @override
  String get createCharacter => 'Create Character';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageSelect => 'Select Language';
}
