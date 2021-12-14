import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quest_system/internal/quest_system.dart';

import '../quest.dart';

/// [QuestSequenceBuilder] 和 [QuestBuilder] 很像，前者对应任务序列，后者对应任务或任务组
/// 它们的差异很小，小到可以通过泛型实现，不过考虑到可能出现的差异性，目前决定分开定义
class QuestSequenceBuilder extends StatefulWidget {
  final Object questId;

  final Function(QuestSequence?) builder;

  QuestSequenceBuilder({
    required this.questId,
    required this.builder,
  }) : super(key: ValueKey(questId));

  @override
  _QuestSequenceBuilderState createState() => _QuestSequenceBuilderState();
}

class _QuestSequenceBuilderState extends State<QuestSequenceBuilder> {
  QuestSequence? quest;
  StreamSubscription? _sub;

  @override
  void initState() {
    quest = QuestSystem.getSequence(widget.questId);
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
