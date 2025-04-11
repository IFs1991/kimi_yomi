import 'package:flutter/material.dart';

class DiagnosisCard extends StatelessWidget {
  final String typeName;
  final int score;
  final VoidCallback onDetailsPressed;

  const DiagnosisCard({
    Key? key,
    required this.typeName,
    required this.score,
    required this.onDetailsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: onDetailsPressed,
                child: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
};