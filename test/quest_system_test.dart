import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_system/internal/checker.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/json_export_visitor.dart';
import 'package:quest_system/internal/visitor/json_import_visitor.dart';

enum MyQuestCondition { c1, c2, c3, c4, c5, c6 }

enum QuestSeqId {
  seq1,
  seq2,
}
enum MyQuestId {
  q1,
  q2,
  q3,
  q4,
  q5,
  q6,
}

main() {
  late CustomTrigger ct;

  setUpAll(() {
    ct = CustomTrigger.instance;
    QuestSystem.addTrigger(ct);
  });

  setUp(() {
    QuestSystem.root.clear();
    QuestSystem.questCache.clear();
    QuestSystem.seqCache.clear();
  });

  test("single task queue", () {
    QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
      Quest(
        id: MyQuestId.q1,
        triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
        completeChecker: QuestChecker.condition(MyQuestCondition.c2),
      ),
      Quest(
        id: MyQuestId.q2,
        triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
        completeChecker: QuestChecker.condition(MyQuestCondition.c2),
      )
    ]));
    QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
      Quest(
        id: MyQuestId.q3,
        triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
        completeChecker: QuestChecker.condition(MyQuestCondition.c2),
      )
    ]));

    final q1 = QuestSystem.getQuest(MyQuestId.q1)!;
    final q2 = QuestSystem.getQuest(MyQuestId.q2)!;
    final q3 = QuestSystem.getQuest(MyQuestId.q3)!;

    expect(q1.status, QuestStatus.inactive);
    expect(q3.status, QuestStatus.inactive);
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c1));
    expect(q1.status, QuestStatus.activated);
    expect(q3.status, QuestStatus.activated);
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c2));
    expect(q1.status, QuestStatus.completed);
    expect(q3.status, QuestStatus.completed);

    // quest checker should not effect the inactive quests.
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
  });

  test("auto active sub-quests, and manually complete parent quest", () {
    QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: MyQuestId.q4,
          triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
          completeChecker: QuestChecker.condition(MyQuestCondition.c2),
          children: [
            Quest.autoTrigger(
              id: MyQuestId.q5,
              completeChecker: QuestChecker.condition(MyQuestCondition.c3),
            ),
            Quest.autoTrigger(
              id: MyQuestId.q6,
              completeChecker: QuestChecker.condition(MyQuestCondition.c4),
            ),
          ])
    ]));

    final q = QuestSystem.getQuest<QuestGroup>(MyQuestId.q4)!;

    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c1));
    expect(q.status, QuestStatus.activated);
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    expect(q.children[0].status, QuestStatus.activated);
    expect(q.children[1].status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c3));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.activated);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c4));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.completed);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c2));
    expect(q.status, QuestStatus.completed);
  });

  test("auto active sub-quests, and auto complete parent quest", () {
    QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: MyQuestId.q1,
          triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: MyQuestId.q5,
              completeChecker: QuestChecker.condition(MyQuestCondition.c3),
            ),
            Quest.autoTrigger(
              id: MyQuestId.q6,
              completeChecker: QuestChecker.condition(MyQuestCondition.c4),
            ),
          ])
    ]));

    final q = QuestSystem.root[0];

    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c1));
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c3));
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c4));

    expect(q.status, QuestStatus.completed);
  });

  test("json exporter", () {
    QuestSystem.addSequence(QuestSequence(id: QuestSeqId.seq1, quests: [
      QuestGroup(
          id: MyQuestId.q1,
          triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: MyQuestId.q2,
              completeChecker: QuestChecker.condition(MyQuestCondition.c2),
            ),
          ]),
      Quest(
        id: MyQuestId.q3,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c3),
      ),
    ]));
    QuestSystem.addSequence(QuestSequence(id: MyQuestId.q4, quests: [
      Quest(
        id: MyQuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c5),
      )
    ]));

    final exporter = JsonExportVisitor();
    var data = QuestSystem.root.accept(exporter);
    expect(
        jsonEncode(data),
        jsonEncode({
          "QuestSeqId.seq1": {"pointer": "QuestId.q1"},
          "QuestId.q1": {"status": 0},
          "QuestId.q2": {"status": 1},
          "QuestId.q3": {"status": 1},
          "QuestId.q4": {"pointer": "QuestId.q5"},
          "QuestId.q5": {"status": 1}
        }));
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c1));
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c2));
    ct.dispatch(QuestTriggerData(condition: MyQuestCondition.c3));
    data = QuestSystem.root.accept(exporter);
    final matcher = {
      "QuestSeqId.seq1": {"pointer": null},
      "QuestId.q1": {"status": 2},
      "QuestId.q2": {"status": 2},
      "QuestId.q3": {"status": 2},
      "QuestId.q4": {"pointer": "QuestId.q5"},
      "QuestId.q5": {"status": 1}
    };
    expect(jsonEncode(data), jsonEncode(matcher));
  });
  test("json importer", () {
    QuestSystem.addSequence(QuestSequence(id: QuestSeqId.seq1, quests: [
      QuestGroup(
          id: MyQuestId.q1,
          triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: MyQuestId.q2,
              completeChecker: QuestChecker.condition(MyQuestCondition.c2),
            ),
          ]),
      Quest(
        id: MyQuestId.q3,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c3),
      ),
    ]));

    QuestSystem.addSequence(QuestSequence(id: MyQuestId.q4, quests: [
      Quest(
        id: MyQuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c5),
      )
    ]));
    final matcher = {
      "QuestSeqId.seq1": {"pointer": null},
      "QuestId.q1": {"status": 2},
      "QuestId.q2": {"status": 1},
      "QuestId.q3": {"status": 2},
      "QuestId.q4": {"pointer": "QuestId.q5"},
      "QuestId.q5": {"status": 1}
    };

    QuestSystem.root.accept(JsonImportVisitor(matcher));

    var data = QuestSystem.root.accept(JsonExportVisitor());
    expect(jsonEncode(data), jsonEncode(matcher));
  });
  // test("listener should be triggered when new sequences added", () async {});
}
