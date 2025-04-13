import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final int currentValue;
  final Function(int) onValueChanged;
  final int questionNumber;
  final int totalQuestions;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.currentValue,
    required this.onValueChanged,
    required this.questionNumber,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $questionNumber of $totalQuestions',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Slider(
              value: currentValue.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _getLabelForValue(currentValue),
              onChanged: (value) => onValueChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelForValue(int value) {
    switch (value) {
      case 1: return 'Strongly Disagree';
      case 2: return 'Disagree';
      case 3: return 'Neutral';
      case 4: return 'Agree';
      case 5: return 'Strongly Agree';
      default: return '';
    }
  }
}