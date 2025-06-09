import 'package:flutter/material.dart';

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Earn Money")),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.card_giftcard, color: Colors.blue),
            title: Text("Scratch Card"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.casino, color: Colors.green),
            title: Text("Spin & Earn"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.video_collection, color: Colors.red),
            title: Text("Watch Ads to Earn"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.discount, color: Colors.orange),
            title: Text("Promo Codes"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
