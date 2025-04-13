import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class CompatibilityChart extends StatelessWidget {
  final double score;
  final String advice;
  final Map<String, double> dataMap;

  CompatibilityChart({
    required this.score,
    required this.advice,
    required this.dataMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '相性診断結果',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            PieChart(
              dataMap: dataMap,
              chartRadius: MediaQuery.of(context).size.width / 3,
              legendOptions: LegendOptions(
                showLegends: true,
                legendPosition: LegendPosition.bottom,
              ),
              chartValuesOptions: ChartValuesOptions(
                showChartValuesInPercentage: true,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '相性スコア: ${score.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'アドバイス:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}