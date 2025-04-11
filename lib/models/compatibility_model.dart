import 'package:flutter/foundation.dart';
import 'user_model.dart';

@immutable
class Compatibility {
  final String id;
  final String user1Id;
  final String user2Id;
  final double totalScore;
  final CompatibilityDetails details;
  final String description;
  final List<String> recommendations;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  const Compatibility({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.totalScore,
    required this.details,
    required this.description,
    required this.recommendations,
    required this.calculatedAt,
    required this.expiresAt,
  });

  factory Compatibility.fromJson(Map<String, dynamic> json) {
    return Compatibility(
      id: json['id'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      totalScore: json['totalScore'] as double,
      details: CompatibilityDetails.fromJson(json['details']),
      description: json['description'] as String,
      recommendations: List<String>.from(json['recommendations']),
      calculatedAt: DateTime.parse(json['calculatedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'totalScore': totalScore,
      'details': details.toJson(),
      'description': description,
      'recommendations': recommendations,
      'calculatedAt': calculatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

@immutable
class CompatibilityDetails {
  final double valueScore;     // 価値観の一致度
  final double interestScore;  // 興味関心の一致度
  final double lifestyleScore; // 生活習慣の一致度
  final double emotionScore;   // 感情的な相性

  const CompatibilityDetails({
    required this.valueScore,
    required this.interestScore,
    required this.lifestyleScore,
    required this.emotionScore,
  });

  factory CompatibilityDetails.fromJson(Map<String, dynamic> json) {
    return CompatibilityDetails(
      valueScore: json['valueScore'] as double,
      interestScore: json['interestScore'] as double,
      lifestyleScore: json['lifestyleScore'] as double,
      emotionScore: json['emotionScore'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valueScore': valueScore,
      'interestScore': interestScore,
      'lifestyleScore': lifestyleScore,
      'emotionScore': emotionScore,
    };
  }

  List<double> toList() {
    return [valueScore, interestScore, lifestyleScore, emotionScore];
  }

  static List<String> categories = [
    '価値観',
    '興味関心',
    '生活習慣',
    '感情面',
  ];
}

@immutable
class DailyCompatibility {
  final String id;
  final String userId;
  final String matchedUserId;
  final Compatibility compatibility;
  final DateTime date;

  const DailyCompatibility({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    required this.compatibility,
    required this.date,
  });

  factory DailyCompatibility.fromJson(Map<String, dynamic> json) {
    return DailyCompatibility(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchedUserId: json['matchedUserId'] as String,
      compatibility: Compatibility.fromJson(json['compatibility']),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'matchedUserId': matchedUserId,
      'compatibility': compatibility.toJson(),
      'date': date.toIso8601String(),
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}