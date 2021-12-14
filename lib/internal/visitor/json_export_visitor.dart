import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

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
    assert(!questSequence.id.toString().startsWith("Instance of"),
        "Custom id must override toString() to provide a unique identifier.");

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
    assert(!questGroup.id.toString().startsWith("Instance of"),
        "Custom id must override toString() to provide a unique identifier.");

    _result[questGroup.id.toString()] = {
      "status": questGroup.status.index,
    };
    for (var e in questGroup.children) {
      e.accept(this);
    }
  }

  @override
  visitQuest(Quest quest) {
    assert(!quest.id.toString().startsWith("Instance of"),
        "Custom id must override toString() to provide a unique identifier.");

    _result[quest.id.toString()] = {
      "status": quest.status.index,
    };
  }
}
