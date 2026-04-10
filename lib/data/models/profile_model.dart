import 'package:football_manager/domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.username,
    required super.email,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: (json['username'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'email': email};
  }
}
