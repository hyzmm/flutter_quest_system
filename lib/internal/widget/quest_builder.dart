import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guidance_system/internal/guidance_system.dart';

import '../quest.dart';

class QuestBuilder<T extends Quest> extends StatefulWidget {
  final Object? questId;
  final T? quest;

  final Widget Function(T?) builder;

  const QuestBuilder.id(this.questId, {Key? key, required this.builder})
      : quest = null,
        super(key: key);

  const QuestBuilder.quest(this.quest, {Key? key, required this.builder})
      : questId = null,
        super(key: key);

  @override
  _QuestBuilderState createState() => _QuestBuilderState<T>();
}

class _QuestBuilderState<T extends Quest> extends State<QuestBuilder<T>> {
  T? quest;
  StreamSubscription? _sub;

  @override
  void initState() {
    quest = widget.quest ?? GuidanceSystem.getQuest<T>(widget.questId!);
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
