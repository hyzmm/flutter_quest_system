import 'dart:developer';

import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class QuestCheckVisitor implements QuestNodeVisitor {
  final QuestTriggerData data;

  const QuestCheckVisitor(this.data);

  @override
  visitQuestRoot(QuestRoot questRoot) {
    /// avoid error while remove quest during traversal
    for (var i = questRoot.quests.length - 1; i >= 0; i--) {
      questRoot.quests[i].accept(this);
    }
  }

  @override
  visitQuestSequence(QuestSequence seq) {
    if (QuestSystem.verbose)
      log("Check quest sequence ${seq.id}", name: "QUEST");

    /// Quests completed
    if (seq.progress >= seq.children.length) return;

    final quest = seq.children[seq.progress];
    quest.accept(this);
    if (quest.status == QuestStatus.completed) {
      seq.progress++;
      seq.dispatch(seq);
    }
  }

  @override
  visitQuestGroup(QuestGroup group) {
    if (QuestSystem.verbose)
      log("Check quest group ${group.id}", name: "QUEST");

    // return true if sub quest's status changes
    bool _checkSubQuest(QuestNode q) {
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
          if (QuestSystem.verbose)
            log("Active quest group ${group.id}", name: "QUEST");

          group.status = QuestStatus.activated;
          group.onTrigger?.call();
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
          for (var i = group.children.length - 1; i >= 0; i--) {
            final q = group.children[i];
            if (_checkSubQuest(q)) shouldDispatch = true;
            if (q.status != QuestStatus.completed) childrenCompleted = false;
          }
        }
        if (childrenCompleted && group.completeChecker.check(data)) {
          if (QuestSystem.verbose) {
            log("Complete quest group ${group.id}", name: "QUEST");
          }

          group.status = QuestStatus.completed;
          group.onComplete?.call();

          shouldDispatch = true;
        }
        break;
      case QuestStatus.completed:
        break;
    }

    if (shouldDispatch) group.dispatch(group);
  }

  @override
  visitQuest(Quest quest) {
    if (QuestSystem.verbose) log("Check quest ${quest.id}", name: "QUEST");

    switch (quest.status) {
      case QuestStatus.inactive:
        if (quest.triggerChecker.check(data)) {
          if (QuestSystem.verbose)
            log("Active quest ${quest.id}", name: "QUEST");
          quest.status = QuestStatus.activated;
          quest.onTrigger?.call();
          quest.dispatch(quest);
        }
        break;
      case QuestStatus.activated:
        if (quest.completeChecker.check(data)) {
          if (QuestSystem.verbose)
            log("Complete quest ${quest.id}", name: "QUEST");
          quest.status = QuestStatus.completed;
          quest.onComplete?.call();
          quest.dispatch(quest);
        }
        break;
      case QuestStatus.completed:
        break;
    }
  }
}
