import 'package:flutter_test/flutter_test.dart';
import 'package:quest_system/internal/checker.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';

import 'quest_system_test.dart';

main() {
  late CustomTrigger ct;

  setUpAll(() {
    ct = CustomTrigger.instance;
    QuestSystem.addTrigger(ct);
  });

  setUp(() {
    QuestSystem.clear();
  });

  test("test add/remove from a group", () {
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
      QuestGroup(
          id: MyQuestId.q1,
          triggerChecker: QuestChecker.automate(),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: MyQuestId.q2,
              completeChecker: QuestChecker.condition(MyQuestCondition.c1),
            ),
          ]),
    ]));

    final group = QuestSystem.getQuest<QuestGroup>(MyQuestId.q1)!;
    CustomTrigger.instance
        .dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    expect(group.length, 1);
    expect(group.progress, 1);

    group.add(Quest.autoTrigger(
      id: MyQuestId.q3,
      completeChecker: QuestChecker.condition(MyQuestCondition.c2),
    ));

    expect(group.length, 2);
    expect(group.progress, 1);

    CustomTrigger.instance
        .dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    expect(group.progress, 2);
  });
}
