import 'package:flutter/material.dart';
import 'package:your_app/widgets/diagnosis_card.dart';
import 'package:your_app/widgets/compatibility_chart.dart';

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
            CompatibilityChart(),
            SizedBox(height: 20),
            Text(
              'Your Diagnosis Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DiagnosisCard(
              typeName: 'Type A',
              score: 85,
              onTap: () {
                // Handle card tap
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
};