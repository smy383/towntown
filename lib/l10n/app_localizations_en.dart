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

  @override
  String get chatTitle => 'Chat';

  @override
  String get loginRequired => 'Login required';

  @override
  String get noChatRooms => 'No chat rooms';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get messageHint => 'Type a message';

  @override
  String get leaveChat => 'Leave Chat';

  @override
  String get leaveChatConfirm => 'Are you sure you want to leave this chat?';

  @override
  String get leave => 'Leave';

  @override
  String get membershipRequest => 'Request Membership';

  @override
  String get membershipPending => 'Pending';

  @override
  String get membershipMember => 'Member';

  @override
  String get membershipOwner => 'Owner';

  @override
  String get membershipRequestSent => 'Membership request sent';

  @override
  String get membershipAlreadyMember => 'Already a member';

  @override
  String get membershipAlreadyRequested => 'Already requested';

  @override
  String get membershipApprove => 'Approve';

  @override
  String get membershipReject => 'Reject';

  @override
  String get membershipRemove => 'Remove';

  @override
  String get membershipLeave => 'Leave Membership';

  @override
  String get membershipLeaveConfirm =>
      'Are you sure you want to leave this village?';

  @override
  String get membershipRequests => 'Join Requests';

  @override
  String get membershipNoRequests => 'No pending requests';

  @override
  String get membershipApproved => 'Approved';

  @override
  String get membershipRejected => 'Rejected';

  @override
  String get members => 'Members';

  @override
  String memberCount(Object count) {
    return '$count members';
  }

  @override
  String villageCapacityInfo(Object bonus, Object current, Object max) {
    return 'Capacity: $current/$max (+$bonus from members)';
  }

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get invitationSent => 'Invitation sent';

  @override
  String get invitationAlreadySent => 'Already invited';

  @override
  String get invitationReceived => 'You have an invitation';

  @override
  String invitationFrom(Object name, Object village) {
    return '$name invited you to join $village';
  }

  @override
  String get invitationAccept => 'Accept';

  @override
  String get invitationDecline => 'Decline';

  @override
  String get invitationCancel => 'Cancel Invitation';

  @override
  String get invitationAccepted => 'Invitation accepted';

  @override
  String get invitationDeclined => 'Invitation declined';

  @override
  String get invitationCancelled => 'Invitation cancelled';

  @override
  String get myInvitations => 'My Invitations';

  @override
  String get sentInvitations => 'Sent Invitations';

  @override
  String get noInvitations => 'No invitations';

  @override
  String get selectHouseLocation => 'Select house location';

  @override
  String get buildHouseHere => 'Build house here';

  @override
  String get drawYourHouse => 'Draw your house';

  @override
  String get doorGuide => 'Door position';

  @override
  String get completeHouse => 'Complete house';

  @override
  String get villageDraft => 'Draft';

  @override
  String get chiefHouse => 'Chief\'s House';

  @override
  String get houseBuilding => 'Building house...';

  @override
  String get houseSaved => 'House completed!';

  @override
  String get villagePublished => 'Village published!';

  @override
  String get tapToPlaceHouse => 'Tap to place your house';

  @override
  String get changeLocation => 'Change location';
}
