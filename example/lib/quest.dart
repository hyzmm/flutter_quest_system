import 'package:example/main.dart';
import 'package:guidance_system/guidance_system.dart';

enum QuestId { q1, q2, q3, seq2, q4, q5 }
enum QuestCondition { c1, c2, c3, c4 }

extension Quests on QuestId {
  String get title {
    switch (this) {
      case QuestId.q1:
        return "Quest 1";
      case QuestId.q2:
        return "Quest 1 - 1";
      case QuestId.q3:
        return "Quest 1 - 2";
      case QuestId.q4:
        return "Quest 2";
      case QuestId.q5:
        return "Quest 3";
      case QuestId.seq2:
        return "Quest 2 Sequence";
    }
  }
}

initQuests() {
  GuidanceSystem.init(QuestRoot([
    QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: QuestId.q1,
          triggerChecker: QuestChecker.autoActivate(),
          completeChecker: QuestChecker.autoActivate(),
          children: [
            Quest.activatedByParent(
                id: QuestId.q2,
                completeChecker: QuestChecker(
                    condition: const RouteCondition(
                        routeName: routeQ1, isRemove: true))),
            Quest.activatedByParent(
                id: QuestId.q3,
                completeChecker: QuestChecker(condition: QuestCondition.c3)),
          ])
    ]),
    QuestSequence(id: QuestId.seq2, quests: [
      Quest(
          id: QuestId.q4,
          triggerChecker: QuestChecker.autoActivate(),
          completeChecker: QuestChecker(
              condition:
                  const RouteCondition(routeName: routeQ2, isRemove: true))),
      Quest(
          id: QuestId.q5,
          triggerChecker: QuestChecker.autoActivate(),
          completeChecker: QuestChecker(
              condition:
                  const RouteCondition(routeName: routeQ2, isRemove: true)))
    ])
  ]));
}
