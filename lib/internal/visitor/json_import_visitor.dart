import 'dart:developer';

import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

class JsonImportVisitor extends QuestNodeVisitor {
  final Map<String, Map<String, dynamic>> data;

  JsonImportVisitor(this.data);

  @override
  dynamic visitQuestRoot(QuestRoot questRoot) {
    for (var e in questRoot.quests) {
      e.accept(this);
    }
  }

  @override
  visitQuestSequence(QuestSequence questSequence) {
    final item = data[questSequence.id.toString()];
    if (item != null && item["pointer"] != null) {
      final progressIndex = questSequence.quests
          .indexWhere((e) => e.id.toString() == item["pointer"]);
      if (progressIndex > -1) questSequence.progress = progressIndex;
    } else {
      questSequence.progress = questSequence.totalProgress;
    }
    for (var e in questSequence.quests) {
      e.accept(this);
    }
  }

  @override
  visitQuestGroup(QuestGroup questGroup) {
    visitQuest(questGroup);
    questGroup.children.map((e) => e.accept(this));
  }

  @override
  visitQuest(Quest quest) {
    final item = data[quest.id.toString()];
    if (item == null) return;

    final statusIndex = item['status'];
    if (statusIndex != null && statusIndex is int) {
      try {
        quest.status = QuestStatus.values[statusIndex];
      } catch (e) {
        log("Failed to deserialize QuestStatus index $statusIndex",
            name: "GUIDANCE");
      }
    }
  }
}
