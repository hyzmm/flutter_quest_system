import 'package:example/main.dart';
import 'package:quest_system/quest_system.dart';

enum MyQuestId { q1, q2, q3, seq2, q4, q5 }
enum MyQuestCondition { c1, c2, c3, c4 }

extension Quests on MyQuestId {
  String get title {
    switch (this) {
      case MyQuestId.q1:
        return "Quest 1";
      case MyQuestId.q2:
        return "Quest 1 - 1";
      case MyQuestId.q3:
        return "Quest 1 - 2";
      case MyQuestId.q4:
        return "Quest 2";
      case MyQuestId.q5:
        return "Quest 3";
      case MyQuestId.seq2:
        return "Quest 2 Sequence";
    }
  }
}

initQuests() {
  QuestSystem.root.on((q) {
    print(q);
  });
  QuestSystem.addSequences([
    QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: MyQuestId.q1,
          triggerChecker: QuestChecker.automate(),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
                id: MyQuestId.q2,
                completeChecker: QuestChecker.condition(
                    const RouteCondition(routeName: routeQ1, isRemove: true))),
            Quest.autoTrigger(
                id: MyQuestId.q3,
                completeChecker: QuestChecker.condition(MyQuestCondition.c3)),
          ])
    ]),
    QuestSequence(id: MyQuestId.seq2, quests: [
      Quest(
          id: MyQuestId.q4,
          triggerChecker: QuestChecker.automate(),
          completeChecker: QuestChecker.condition(
              const RouteCondition(routeName: routeQ2, isRemove: true))),
      Quest(
          id: MyQuestId.q5,
          triggerChecker: QuestChecker.automate(),
          completeChecker: QuestChecker.condition(
              const RouteCondition(routeName: routeQ2, isRemove: true)))
    ])
  ]);

  QuestSystem.getSequence(MyQuestId.seq2)!.on((q) {
    if (q.status == QuestStatus.completed) {
      QuestSystem.removeSequence(MyQuestId.seq2);
    }
  });
}
