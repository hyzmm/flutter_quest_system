import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/quest_check_visitor.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class QuestSystem {
  static bool verbose = false;

  static final Map<Object, QuestNode> questMap = {};

  static final QuestRoot _root = QuestRoot([]);

  static final List<QuestTrigger> _triggers = [];

  QuestSystem._();

  static dynamic acceptVisitor(QuestNodeVisitor visitor) =>
      _root.accept(visitor);

  static void addSequence(QuestSequence seq) {
    _root.add(seq);
    _root.dispatch(_root);
  }

  static void addSequences(List<QuestSequence> seq) {
    _root.addAll(seq);
    _root.dispatch(_root);
  }

  static void removeSequence(Object id) {
    final seq = questMap.remove(id) as QuestSequence?;
    if (seq != null)_root.remove(seq);
  }

  static T? getQuest<T extends QuestNode>(Object id) => questMap[id] as T;

  static void clear() {
    _root.clear();
    questMap.clear();
  }

  static void addTrigger(QuestTrigger trigger) {
    if (trigger.isDestroyed) {
      throw TriggerDestroyedException();
    }

    _triggers.add(trigger);
    trigger.on(_onTrigger);
  }

  static void removeTrigger(QuestTrigger trigger) {
    _triggers.remove(trigger);
    trigger.destroy();
  }

  static StreamSubscription listenerAll(VoidCallback callback) =>
      _root.on((_) => callback());

  static void _onTrigger(QuestTriggerData data) {
    if (verbose) log("Trigger Check with condition ${data.condition}", name: "QUEST");
    _root.accept(QuestCheckVisitor(data));
  }
}
