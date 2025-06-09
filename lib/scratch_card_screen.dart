import 'package:flutter/material.dart';

class ScratchCardScreen extends StatelessWidget {
  const ScratchCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scratch & Win")),
      body: Center(
        child: Text(
          "Scratch Here!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
