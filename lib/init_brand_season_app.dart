import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const InitBrandSeasonApp());
}

class InitBrandSeasonApp extends StatelessWidget {
  const InitBrandSeasonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                final deadline = DateTime.now().add(const Duration(days: 30));
                
                await FirebaseFirestore.instance.collection('brand_seasons').add({
                  'phase': 'input',
                  'isActive': true,
                  'inputDeadline': Timestamp.fromDate(deadline),
                  'votingDeadline': null,
                  'winnerId': null,
                });
                
                print('✅ Brand season created!');
                print('📅 Deadline: $deadline');
              } catch (e) {
                print('❌ Error: $e');
              }
            },
            child: const Text('Create Brand Season'),
          ),
        ),
      ),
    );
  }
}
