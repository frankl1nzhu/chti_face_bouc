import 'package:flutter/material.dart';

class EmptyBody extends StatelessWidget {
  const EmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aucune donnée'), // Or CircularProgressIndicator() ?
    ); // Center
  }
}

class EmptyScaffold extends StatelessWidget {
  const EmptyScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chargement...")), // Optional title
      body:
          const EmptyBody(), // Or directly use Center(child: CircularProgressIndicator())
    ); // Scaffold
  }
}
