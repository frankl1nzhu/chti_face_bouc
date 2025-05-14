import 'package:flutter/material.dart';

class EmptyBody extends StatelessWidget {
  const EmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Aucune donnée'));
  }
}

class EmptyScaffold extends StatelessWidget {
  const EmptyScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chargement...")),
      body: const EmptyBody(),
    );
  }
}
