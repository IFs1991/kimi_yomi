import 'package:flutter/foundation.dart';
import 'user_model.dart';

@immutable
class Question {
  final String id;
  final String content;
  final String category; // O, C, E, A, N
  final int orderIndex;
  final bool isReversed;

  const Question({
    required this.id,
    required this.content,
    required this.category,
    required this.orderIndex,
    this.isReversed = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      orderIndex: json['orderIndex'] as int,
      isReversed: json['isReversed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'orderIndex': orderIndex,
      'isReversed': isReversed,
    };
  }
}

@immutable
class DiagnosisResult {
  final String id;
  final String userId;
  final Big5Score scores;
  final DateTime diagnosisDate;
  final List<PersonalityInsight> insights;

  const DiagnosisResult({
    required this.id,
    required this.userId,
    required this.scores,
    required this.diagnosisDate,
    required this.insights,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      scores: Big5Score.fromJson(json['scores']),
      diagnosisDate: DateTime.parse(json['diagnosisDate']),
      insights: (json['insights'] as List)
          .map((e) => PersonalityInsight.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scores': scores.toJson(),
      'diagnosisDate': diagnosisDate.toIso8601String(),
      'insights': insights.map((e) => e.toJson()).toList(),
    };
  }
}

@immutable
class PersonalityInsight {
  final String trait;
  final String description;
  final List<String> strengths;
  final List<String> challenges;
  final List<String> recommendations;

  const PersonalityInsight({
    required this.trait,
    required this.description,
    required this.strengths,
    required this.challenges,
    required this.recommendations,
  });

  factory PersonalityInsight.fromJson(Map<String, dynamic> json) {
    return PersonalityInsight(
      trait: json['trait'] as String,
      description: json['description'] as String,
      strengths: List<String>.from(json['strengths']),
      challenges: List<String>.from(json['challenges']),
      recommendations: List<String>.from(json['recommendations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trait': trait,
      'description': description,
      'strengths': strengths,
      'challenges': challenges,
      'recommendations': recommendations,
    };
  }
}

@immutable
class DiagnosisSession {
  final String id;
  final String userId;
  final int currentQuestionIndex;
  final bool isComplete;
  final Map<String, int> answers;

  const DiagnosisSession({
    required this.id,
    required this.userId,
    this.currentQuestionIndex = 0,
    this.isComplete = false,
    required this.answers,
  });

  DiagnosisSession copyWith({
    String? id,
    String? userId,
    int? currentQuestionIndex,
    bool? isComplete,
    Map<String, int>? answers,
  }) {
    return DiagnosisSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isComplete: isComplete ?? this.isComplete,
      answers: answers ?? Map.from(this.answers),
    );
  }

  factory DiagnosisSession.fromJson(Map<String, dynamic> json) {
    return DiagnosisSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      currentQuestionIndex: json['currentQuestionIndex'] as int,
      isComplete: json['isComplete'] as bool,
      answers: Map<String, int>.from(json['answers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'currentQuestionIndex': currentQuestionIndex,
      'isComplete': isComplete,
      'answers': answers,
    };
  }
}