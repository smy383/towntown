import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? characterName;
  final DateTime joinDate;
  final String loginProvider; // 'google', 'apple', 'kakao'

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.characterName,
    required this.joinDate,
    required this.loginProvider,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      characterName: data['characterName'],
      joinDate: data['joinDate'] != null
          ? (data['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      loginProvider: data['loginProvider'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'characterName': characterName,
      'joinDate': Timestamp.fromDate(joinDate),
      'loginProvider': loginProvider,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? characterName,
    DateTime? joinDate,
    String? loginProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      characterName: characterName ?? this.characterName,
      joinDate: joinDate ?? this.joinDate,
      loginProvider: loginProvider ?? this.loginProvider,
    );
  }
}
