import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';

class DispatchVisitor implements QuestNodeVisitor {
  const DispatchVisitor();

  @override
  visitQuest(Quest quest) {
    quest.dispatch(quest);
  }

  @override
  visitQuestGroup(QuestGroup questGroup) {
    // questGroup.disconnectListeners();
    // questGroup.dispatch(questGroup);

    for (var e in questGroup.children) {
      e.accept(this);
    }
  }

  @override
  visitQuestRoot(QuestRoot questRoot) {
    // for (var e in questRoot.quests) {
    //   e.accept(this);
    // }
    throw UnimplementedError("unimplemented");
  }

  @override
  visitQuestSequence(QuestSequence questSequence) {
    questSequence.disconnectListeners();
    // questSequence.dispatch(questSequence);

    for (var e in questSequence.children) {
      e.accept(this);
    }
  }
}
