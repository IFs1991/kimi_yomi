import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/diagnosis_result.dart';
import '../../widgets/radar_chart.dart';
import '../../widgets/result_card.dart';

class ResultScreen extends StatelessWidget {
  final DiagnosisResult result;

  const ResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '性格診断結果',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              // Big5 Radar Chart
              SizedBox(
                height: 300,
                child: RadarChart(
                  scores: result.big5Scores,
                ),
              ),
              const SizedBox(height: 24),
              // Detailed Results Cards
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.detailedScores.length,
                itemBuilder: (context, index) {
                  return ResultCard(
                    score: result.detailedScores[index],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to compatibility check
                },
                child: const Text('相性診断を行う'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
