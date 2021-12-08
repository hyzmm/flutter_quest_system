import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guidance_system/internal/guidance_system.dart';

import '../quest.dart';

class QuestBuilder extends StatefulWidget {
  final Object questId;

  final Function(Quest?) builder;

  const QuestBuilder({
    Key? key,
    required this.questId,
    required this.builder,
  }) : super(key: key);

  @override
  _QuestBuilderState createState() => _QuestBuilderState();
}

class _QuestBuilderState extends State<QuestBuilder> {
  Quest? quest;
  StreamSubscription? _sub;

  @override
  void initState() {
    quest = GuidanceSystem.getQuest(widget.questId);
    _sub = quest?.on((q) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(quest);
  }
}
