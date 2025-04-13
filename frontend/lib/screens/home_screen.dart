import 'package:flutter/material.dart';
import 'package:kimi_yomi/widgets/diagnosis_card.dart';
import 'package:kimi_yomi/widgets/compatibility_chart.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Compatibility',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CompatibilityChart(
              score: 75.5,
              advice: "Keep up the good work!",
              dataMap: {"Factor A": 5, "Factor B": 3, "Factor C": 2},
            ),
            SizedBox(height: 20),
            Text(
              'Your Diagnosis Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DiagnosisCard(
              typeName: 'Type A',
              score: 85,
              onDetailsPressed: () {
                print("Details pressed");
              },
            ),
            SizedBox(height: 20),
            Text(
              'Content Viewer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Content 1'),
                    onTap: () {
                      // Handle content tap
                    },
                  ),
                  ListTile(
                    title: Text('Content 2'),
                    onTap: () {
                      // Handle content tap
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}