import 'dart:developer';

import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class JsonImportVisitor implements QuestNodeVisitor<void> {
  final Map<String, dynamic> data;

  JsonImportVisitor(this.data);

  @override
  void visitQuestRoot(QuestRoot questRoot) {
    for (var e in questRoot.quests) {
      e.accept(this);
    }
  }

  @override
  void visitQuestSequence(QuestSequence questSequence) {
    final item = data[questSequence.id.toString()];
    if (item != null && item.containsKey("pointer")) {
      final progressIndex = questSequence.children
          .indexWhere((e) => e.id.toString() == item["pointer"]);
      if (progressIndex > -1) {
        questSequence.progress = progressIndex;
      } else {
        questSequence.progress = questSequence.totalProgress;
      }
    } else {
      questSequence.progress = 0;
    }
    for (var e in questSequence.children) {
      e.accept(this);
    }
  }

  @override
  void visitQuestGroup(QuestGroup questGroup) {
    visitQuest(questGroup);
    for (var e in questGroup.children) {
      e.accept(this);
    }
  }

  @override
  void visitQuest(QuestNode quest) {
    final item = data[quest.id.toString()];
    if (item == null) return;

    final statusIndex = item['status'];
    if (statusIndex != null && statusIndex is int) {
      try {
        quest.status = QuestStatus.values[statusIndex];
      } catch (e) {
        log("Failed to deserialize QuestStatus index $statusIndex",
            name: "QUEST");
      }
    }
  }
}
