import 'package:flutter/foundation.dart';

@immutable
class User {
  final String id;
  final String name;
  final String email;
  final DateTime? birthDate;
  final String? gender;
  final String? profileImage;
  final Big5Score? personalityScore;
  final DateTime? lastDiagnosisDate;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.birthDate,
    this.gender,
    this.profileImage,
    this.personalityScore,
    this.lastDiagnosisDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'] as String?,
      profileImage: json['profileImage'] as String?,
      personalityScore: json['personalityScore'] != null
          ? Big5Score.fromJson(json['personalityScore'])
          : null,
      lastDiagnosisDate: json['lastDiagnosisDate'] != null
          ? DateTime.parse(json['lastDiagnosisDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'profileImage': profileImage,
      'personalityScore': personalityScore?.toJson(),
      'lastDiagnosisDate': lastDiagnosisDate?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? birthDate,
    String? gender,
    String? profileImage,
    Big5Score? personalityScore,
    DateTime? lastDiagnosisDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      personalityScore: personalityScore ?? this.personalityScore,
      lastDiagnosisDate: lastDiagnosisDate ?? this.lastDiagnosisDate,
    );
  }
}

@immutable
class Big5Score {
  final double openness;
  final double conscientiousness;
  final double extraversion;
  final double agreeableness;
  final double neuroticism;

  const Big5Score({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });

  factory Big5Score.fromJson(Map<String, dynamic> json) {
    return Big5Score(
      openness: json['openness'] as double,
      conscientiousness: json['conscientiousness'] as double,
      extraversion: json['extraversion'] as double,
      agreeableness: json['agreeableness'] as double,
      neuroticism: json['neuroticism'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openness': openness,
      'conscientiousness': conscientiousness,
      'extraversion': extraversion,
      'agreeableness': agreeableness,
      'neuroticism': neuroticism,
    };
  }

  List<double> toList() {
    return [
      openness,
      conscientiousness,
      extraversion,
      agreeableness,
      neuroticism,
    ];
  }

  static List<String> traits = [
    '開放性',
    '誠実性',
    '外向性',
    '協調性',
    '神経症的傾向',
  ];
}