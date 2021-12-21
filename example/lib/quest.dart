import 'package:example/main.dart';
import 'package:quest_system/quest_system.dart';

// 串行任务的 id
enum MyQuestSeqId { seq1, seq2 }
// 任务组的 id
enum MyQuestGroupId { group1 }
// 单项任务的 id
enum MyQuestId { q1, q2, q3, q4 }

extension Quests on MyQuestId {
  String get title {
    switch (this) {
      case MyQuestId.q1:
        return "Quest 1 - 1";
      case MyQuestId.q2:
        return "Quest 1 - 2";
      case MyQuestId.q3:
        return "Quest 3";
      case MyQuestId.q4:
        return "Quest 4";
    }
  }
}

initQuests() {
  QuestSystem.addSequences([
    QuestSequence(id: MyQuestSeqId.seq1, quests: [
      QuestGroup(
          id: MyQuestGroupId.group1,
          triggerChecker: QuestChecker.automate(),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
                id: MyQuestId.q1,
                completeChecker: QuestChecker.condition(
                    const RouteCondition(routeName: routeQ1, isRemove: true))),
            Quest.autoTrigger(
                id: MyQuestId.q2,
                completeChecker: QuestChecker.condition(MyQuestId.q2)),
          ])
    ]),
    QuestSequence(id: MyQuestSeqId.seq2, quests: [
      Quest.autoTrigger(
          id: MyQuestId.q3,
          completeChecker: QuestChecker.condition(
              const RouteCondition(routeName: routeQ2, isRemove: true))),
      Quest.autoTrigger(
          id: MyQuestId.q4,
          completeChecker: QuestChecker.condition(
              const RouteCondition(routeName: routeQ2, isRemove: true)))
    ])
  ]);

  QuestSystem.getQuest<QuestSequence>(MyQuestSeqId.seq2)!.on((q) {
    if (q.status == QuestStatus.completed) {
      QuestSystem.removeSequence(MyQuestSeqId.seq2);
    }
  });
}
