import 'package:flutter/material.dart';

class SearchResultsScreen extends StatelessWidget {
  final String keyword;

  const SearchResultsScreen({super.key, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج البحث'),
      ),
      body: Center(
        child: Text('نتائج البحث عن: $keyword'),
      ),
    );
  }
}
