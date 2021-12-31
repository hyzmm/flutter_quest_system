import 'package:flutter/material.dart';

class Quest2Page extends StatefulWidget {
  const Quest2Page({Key? key}) : super(key: key);

  @override
  _Quest2PageState createState() => _Quest2PageState();
}

class _Quest2PageState extends State<Quest2Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quest 2")),
      body: const Center(child: Text("Back to complete quest 2")),
    );
  }
}
