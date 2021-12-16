import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/quest_check_visitor.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class QuestSystem {
  static QuestSystem instance = QuestSystem._();

  static final Map<Object, QuestSequence> seqCache = {};

  static final Map<Object, Quest> questCache = {};

  static final QuestRoot _root = QuestRoot([]);

  static final List<QuestTrigger> _triggers = [];

  QuestSystem._();

  static void clear() => _root.clear();

  static dynamic acceptVisitor(QuestNodeVisitor visitor) =>
      _root.accept(visitor);

  static void addSequence(QuestSequence seq) {
    _root.add(seq);
    _root.dispatch(_root);
  }

  static void removeSequence(Object id) {
    if (seqCache.containsKey(id)) _root.remove(seqCache[id]!);
  }

  static void addSequences(List<QuestSequence> seq) {
    _root.addAll(seq);
    _root.dispatch(_root);
  }

  static QuestSequence? getSequence(Object id) => seqCache[id];

  static T? getQuest<T extends Quest>(Object id) => questCache[id] as T;

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
    _root.accept(QuestCheckVisitor(data));
  }
}
