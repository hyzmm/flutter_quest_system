import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/visitor/quest_check_visitor.dart';

class GuidanceSystem {
  static GuidanceSystem instance = GuidanceSystem._();

  static final Map<Object, QuestSequence> seqCache = {};

  static final Map<Object, Quest> questCache = {};

  static final QuestRoot root = QuestRoot([]);

  static final List<QuestTrigger> _triggers = [];

  GuidanceSystem._();

  static void addSequence(QuestSequence seq) {
    root.add(seq);
    root.dispatch(root);
  }

  static void removeSequence(Object id) {
    if (seqCache.containsKey(id)) root.remove(seqCache[id]!);
  }

  static void addSequences(List<QuestSequence> seq) {
    root.addAll(seq);
    root.dispatch(root);
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

  static void _onTrigger(QuestTriggerData data) {
    root.accept(QuestCheckVisitor(data));
  }
}
