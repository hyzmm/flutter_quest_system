import 'package:flutter/foundation.dart';
import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';

class GuidanceSystem {
  static late GuidanceSystem instance = GuidanceSystem();

  static final Map<Object, QuestSequence> seqCache = {};

  static final Map<Object, Quest> questCache = {};

  @visibleForTesting
  @protected
  final List<QuestSequence> questPaths = [];

  final List<QuestTrigger> _triggers = [];

  void addSequence(QuestSequence quest) {
    questPaths.add(quest);
  }

  QuestSequence? getSequence(Object id) => seqCache[id];

  Quest? getQuest(Object id) => questCache[id];

  void addTrigger(QuestTrigger trigger) {
    if (trigger.isDestroyed()) {
      throw TriggerDestroyedException();
    }

    _triggers.add(trigger);
    trigger.on(_onTrigger);
  }

  void removeTrigger(QuestTrigger trigger) {
    _triggers.remove(trigger);
    trigger.destroy();
  }

  void _onTrigger(QuestTriggerData data) {
    for (var i = questPaths.length - 1; i >= 0; i--) {
      final quest = questPaths[i];
      quest.check(data);
    }
  }
}
