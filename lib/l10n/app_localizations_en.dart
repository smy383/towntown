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

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navTown => 'Town';

  @override
  String get navSettings => 'Settings';

  @override
  String get feedTitle => 'Feed';

  @override
  String get feedEmpty => 'No news yet';

  @override
  String get feedEmptyDesc => 'Join a village to see updates here';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search villages or users';

  @override
  String get searchVillages => 'Villages';

  @override
  String get searchUsers => 'Users';

  @override
  String get searchEmpty => 'No results found';

  @override
  String get townTitle => 'Town';

  @override
  String get townEmpty => 'No villages yet';

  @override
  String get townEmptyDesc => 'Create a village or join others';

  @override
  String get createVillageTitle => 'Create Village';

  @override
  String get villageNameHint => 'Enter village name';

  @override
  String get villageNameLabel => 'Village Name';

  @override
  String get villageCreating => 'Creating your village...';

  @override
  String get villageCreated => 'Village created!';

  @override
  String get villageCreateButton => 'Create Village';

  @override
  String get villageLocation => 'Location';

  @override
  String get villageAlreadyExists => 'You already have a village';

  @override
  String get findingLocation => 'Finding location...';

  @override
  String get yourVillageLocation => 'Your village location';

  @override
  String get allVillages => 'All Villages';

  @override
  String get population => 'Population';

  @override
  String get noVillageYet => 'No villages yet';

  @override
  String get createFirstVillage => 'Create the first village!';

  @override
  String get villageFull => 'Village is full';

  @override
  String get villagePrivate => 'This is a private village';

  @override
  String get villageNotFound => 'Village not found';

  @override
  String villageCapacity(Object current, Object max) {
    return '$current/$max';
  }
}
