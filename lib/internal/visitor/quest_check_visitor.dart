import 'dart:developer';

import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

class QuestCheckVisitor implements QuestNodeVisitor {
  final QuestTriggerData data;

  const QuestCheckVisitor(this.data);

  @override
  visitQuestRoot(QuestRoot questRoot) {
    for (var e in questRoot.quests) {
      e.accept(this);
    }
  }

  @override
  visitQuestSequence(QuestSequence seq) {
    /// Quests completed
    if (seq.progress >= seq.quests.length) return;

    final quest = seq.quests[seq.progress];
    quest.accept(this);
    if (quest.status == QuestStatus.completed) {
      seq.progress++;
      seq.dispatch(seq);
    }
  }

  @override
  visitQuestGroup(QuestGroup group) {
    // return true if sub quest's status changes
    bool _checkSubQuest(Quest q) {
      final oldStatus = q.status;
      q.accept(this);
      final newStatus = q.status;
      return oldStatus != newStatus;
    }

    // Use a flag to trigger dispatch only once
    bool shouldDispatch = false;

    switch (group.status) {
      case QuestStatus.inactive:
        if (group.triggerChecker.check(data)) {
          group.status = QuestStatus.activated;
          // When a query be activated, its children will be activated too
          for (var q in group.children) {
            if (_checkSubQuest(q)) shouldDispatch = true;
          }
          shouldDispatch = true;
        }
        break;
      case QuestStatus.activated:
        // if this quest is a group, it must complete all sub quests, then complete itself
        bool childrenCompleted = true;
        if (group.children.isNotEmpty) {
          for (var q in group.children) {
            if (_checkSubQuest(q)) shouldDispatch = true;
            if (q.status != QuestStatus.completed) childrenCompleted = false;
          }
        }
        if (childrenCompleted && group.completeChecker.check(data)) {
          group.status = QuestStatus.completed;

          shouldDispatch = true;
          log("Complete quest group ${group.id}", name: "GUIDANCE");
        }
        break;
      case QuestStatus.completed:
        break;
    }

    if (shouldDispatch) group.dispatch(group);
  }

  @override
  visitQuest(Quest quest) {
    switch (quest.status) {
      case QuestStatus.inactive:
        if (quest.triggerChecker.check(data)) {
          quest.status = QuestStatus.activated;
          quest.dispatch(quest);
        }
        break;
      case QuestStatus.activated:
        if (quest.completeChecker.check(data)) {
          quest.status = QuestStatus.completed;
          quest.dispatch(quest);
          log("Complete quest ${quest.id}", name: "GUIDANCE");
        }
        break;
      case QuestStatus.completed:
        break;
    }
  }
}
