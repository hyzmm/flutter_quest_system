import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/visitor/quest_check_visitor.dart';

class GuidanceSystem {
  static late GuidanceSystem instance = GuidanceSystem._();

  static final Map<Object, QuestSequence> seqCache = {};

  static final Map<Object, Quest> questCache = {};

  GuidanceSystem._();

  static QuestRoot root = QuestRoot([]);

  final List<QuestTrigger> _triggers = [];

  static void addSequence(QuestSequence seq) {
    root.add(seq);
  }

  static QuestSequence? getSequence(Object id) => seqCache[id];

  static T? getQuest<T extends Quest>(Object id) => questCache[id] as T;

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
    root.accept(QuestCheckVisitor(data));
  }
}
