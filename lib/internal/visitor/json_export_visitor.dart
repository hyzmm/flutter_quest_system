import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

class JsonExportVisitor extends QuestNodeVisitor<Map<String, dynamic>> {
  late List<Map<String, dynamic>> data;

  @override
  void visitQuestRoot(QuestRoot questRoot) {
    data = [];
    for (var e in questRoot.quests) {
      data.add(e.accept(this));
    }
  }

  @override
  Map<String, dynamic> visitQuestSequence(QuestSequence questSequence) {
    return {
      "id": questSequence.id.toString(),
      "quests": questSequence.quests.map((e) => e.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitQuestGroup(QuestGroup questGroup) {
    return {
      "id": questGroup.id.toString(),
      "status": questGroup.status.toString(),
      "children": questGroup.children.map((e) => e.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitQuest(Quest quest) {
    return {
      "id": quest.id.toString(),
      "status": quest.status.toString(),
    };
  }
}
