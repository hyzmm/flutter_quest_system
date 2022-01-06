import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class DisposeVisitor implements QuestNodeVisitor {
  const DisposeVisitor();

  @override
  visitQuest(Quest quest) {
    quest.destroy();
  }

  @override
  visitQuestGroup(QuestGroup questGroup) {
    // questGroup.disconnectListeners();
    // questGroup.dispatch(questGroup);

    questGroup.destroy();
    for (var e in questGroup.children) {
      e.accept(this);
    }
  }

  @override
  visitQuestRoot(QuestRoot questRoot) {
    for (var e in questRoot.quests) {
      e.accept(this);
    }
  }

  @override
  visitQuestSequence(QuestSequence questSequence) {
    questSequence.destroy();

    for (var e in questSequence.children) {
      e.accept(this);
    }
  }
}
