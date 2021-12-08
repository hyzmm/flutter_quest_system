import 'package:flutter/foundation.dart';
import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';

class GuidanceSystem {
  static late GuidanceSystem instance = GuidanceSystem._();

  static final Map<Object, QuestSequence> seqCache = {};

  static final Map<Object, Quest> questCache = {};

  GuidanceSystem._();

  @visibleForTesting
  @protected
  final List<QuestSequence> sequences = [];

  final List<QuestTrigger> _triggers = [];

  static void addSequence(QuestSequence quest) {
    instance.sequences.add(quest);
  }

  static QuestSequence? getSequence(Object id) => seqCache[id];

  static Quest? getQuest(Object id) => questCache[id];

  static void addTrigger(QuestTrigger trigger) {
    if (trigger.isDestroyed()) {
      throw TriggerDestroyedException();
    }

    instance._triggers.add(trigger);
    trigger.on(_onTrigger);
  }

  static void removeTrigger(QuestTrigger trigger) {
    instance._triggers.remove(trigger);
    trigger.destroy();
  }

  static void _onTrigger(QuestTriggerData data) {
    for (var i = instance.sequences.length - 1; i >= 0; i--) {
      final quest = instance.sequences[i];
      quest.check(data);
    }
  }
}
