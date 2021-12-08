import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guidance_system/internal/guidance_system.dart';

import '../quest.dart';

class QuestBuilder<T extends Quest> extends StatefulWidget {
  final Object questId;

  final Widget Function(T?) builder;

  const QuestBuilder({
    Key? key,
    required this.questId,
    required this.builder,
  }) : super(key: key);

  @override
  _QuestBuilderState createState() => _QuestBuilderState<T>();
}

class _QuestBuilderState<T extends Quest> extends State<QuestBuilder<T>> {
  T? quest;
  StreamSubscription? _sub;

  @override
  void initState() {
    quest = GuidanceSystem.getQuest<T>(widget.questId);
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
