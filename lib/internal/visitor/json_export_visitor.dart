import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

class JsonExportVisitor extends QuestNodeVisitor {
  late List<Map<String, dynamic>> data;
  late Map<String, dynamic> _seqNode;

  @override
  void visitQuest(Quest quest) {
    // TODO: implement visitQuest
  }

  @override
  void visitQuestRoot(QuestRoot questRoot) {
    data = [];
  }

  @override
  void visitQuestSequence(QuestSequence questSequence) {
    _seqNode = {
      "id": questSequence.id,
      "quests": [],
    };

    data.add(_seqNode);
  }
}
