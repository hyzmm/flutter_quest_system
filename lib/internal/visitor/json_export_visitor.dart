import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

class JsonExportVisitor extends QuestNodeVisitor {
  final Map<String, Map<String, dynamic>> _result = {};

  @override
  dynamic visitQuestRoot(QuestRoot questRoot) {
    _result.clear();
    for (var e in questRoot.quests) {
      e.accept(this);
    }
    return _result;
  }

  @override
  visitQuestSequence(QuestSequence questSequence) {
    _result[questSequence.id.toString()] = {
      "pointer": questSequence.status == QuestStatus.completed
          ? null
          : questSequence[questSequence.progress].id.toString(),
    };
    for (var e in questSequence.quests) {
      e.accept(this);
    }
  }

  @override
  visitQuestGroup(QuestGroup questGroup) {
    _result[questGroup.id.toString()] = {
      "status": questGroup.status.index,
    };
    questGroup.children.map((e) => e.accept(this));
  }

  @override
  visitQuest(Quest quest) {
    _result[quest.id.toString()] = {
      "status": quest.status.index,
    };
  }
}
