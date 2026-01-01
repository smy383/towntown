// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ネオンタウン';

  @override
  String get homeWelcome => 'どこへ行く?';

  @override
  String get homeSubtitle => '村を作ったり、他の村を訪れてみよう';

  @override
  String get createVillage => '村を作る';

  @override
  String get createVillageDesc => '自分だけの村を作ろう';

  @override
  String get exploreVillage => '村を探検';

  @override
  String get exploreVillageDesc => '他の人の村を見てみよう';

  @override
  String get myVillage => 'マイビレッジ';

  @override
  String get myVillageDesc => '自分の村へ移動します';

  @override
  String get settings => '設定';

  @override
  String get myInfo => 'マイ情報';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => '本当にログアウトしますか?';

  @override
  String get cancel => 'キャンセル';

  @override
  String get comingSoon => '準備中...';

  @override
  String get enterName => '名前を入力してください';

  @override
  String get createCharacter => 'キャラクター作成';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システム設定';

  @override
  String get languageSelect => '言語を選択';

  @override
  String get navHome => 'ホーム';

  @override
  String get navSearch => '検索';

  @override
  String get navTown => 'タウン';

  @override
  String get navSettings => '設定';

  @override
  String get feedTitle => 'フィード';

  @override
  String get feedEmpty => 'まだニュースがありません';

  @override
  String get feedEmptyDesc => '村に参加するとここにニュースが表示されます';

  @override
  String get searchTitle => '検索';

  @override
  String get searchHint => '村やユーザーを検索';

  @override
  String get searchVillages => '村';

  @override
  String get searchUsers => 'ユーザー';

  @override
  String get searchEmpty => '検索結果がありません';

  @override
  String get townTitle => 'タウン';

  @override
  String get townEmpty => '村がありません';

  @override
  String get townEmptyDesc => '村を作るか、他の村に参加しましょう';

  @override
  String get createVillageTitle => '村を作る';

  @override
  String get villageNameHint => '村の名前を入力';

  @override
  String get villageNameLabel => '村の名前';

  @override
  String get villageCreating => '村を作成中...';

  @override
  String get villageCreated => '村が作成されました!';

  @override
  String get villageCreateButton => '村を作る';

  @override
  String get villageLocation => '場所';

  @override
  String get villageAlreadyExists => 'すでに村を持っています';

  @override
  String get findingLocation => '場所を探しています...';

  @override
  String get yourVillageLocation => 'あなたの村の場所';

  @override
  String get allVillages => 'すべての村';

  @override
  String get population => '人口';

  @override
  String get noVillageYet => 'まだ村がありません';

  @override
  String get createFirstVillage => '最初の村を作りましょう!';

  @override
  String get villageFull => '村の定員がいっぱいです';

  @override
  String get villagePrivate => '非公開の村です';

  @override
  String get villageNotFound => '村が見つかりません';

  @override
  String villageCapacity(Object current, Object max) {
    return '$current/$max人';
  }
}
