import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quest_system/internal/quest_system.dart';

import '../quest.dart';

class QuestBuilder<T extends Quest> extends StatefulWidget {
  final Object? questId;
  final T? quest;

  final Widget Function(T?) builder;

  QuestBuilder.id(this.questId, {required this.builder})
      : quest = null,
        super(key: ValueKey(questId));

  QuestBuilder.quest(this.quest, {required this.builder})
      : questId = null,
        super(key: ValueKey(quest!.id));

  @override
  _QuestBuilderState createState() => _QuestBuilderState<T>();
}

class _QuestBuilderState<T extends Quest> extends State<QuestBuilder<T>> {
  T? quest;
  StreamSubscription? _sub;
  StreamSubscription? _rootSub;

  @override
  void initState() {
    quest = widget.quest;
    if (quest == null) {
      quest = QuestSystem.getQuest<T>(widget.questId!);
      // quest unregistered
      if (quest == null) {
        // listener to quest added
        _rootSub = QuestSystem.listenerAll(() {
          quest = QuestSystem.getQuest<T>(widget.questId!);
          if (quest != null) {
            setState(() {});
            _sub = quest!.on((_) => setState(() {}));
            _rootSub!.cancel();
            _rootSub = null;
          }
        });
      }
    }
    _sub = quest?.on((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rootSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(quest);
  }
}
