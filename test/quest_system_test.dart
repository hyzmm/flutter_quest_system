import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_system/internal/checker.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/json_export_visitor.dart';
import 'package:quest_system/internal/visitor/json_import_visitor.dart';

enum MyQuestCondition { c1, c2, c3, c4, c5, c6 }

enum MyQuestSeqId {
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
  QuestSystem.verbose = true;
  late CustomTrigger ct;

  setUpAll(() {
    ct = CustomTrigger.instance;
    QuestSystem.addTrigger(ct);
  });

  setUp(() {
    QuestSystem.clear();
  });

  test("single task queue", () {
    QuestSystem.addQuestContainer(QuestSequence(id: Object(), children: [
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
    QuestSystem.addQuestContainer(QuestSequence(id: Object(), children: [
      Quest(
        id: MyQuestId.q3,
        triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
        completeChecker: QuestChecker.condition(MyQuestCondition.c2),
      )
    ]));

    final q1 = QuestSystem.getQuest<Quest>(MyQuestId.q1)!;
    final q2 = QuestSystem.getQuest<Quest>(MyQuestId.q2)!;
    final q3 = QuestSystem.getQuest<Quest>(MyQuestId.q3)!;

    expect(q1.status, QuestStatus.inactive);
    expect(q3.status, QuestStatus.inactive);
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    expect(q1.status, QuestStatus.activated);
    expect(q3.status, QuestStatus.activated);
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    expect(q1.status, QuestStatus.completed);
    expect(q3.status, QuestStatus.completed);

    // quest checker should not effect the inactive quests.
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
  });

  test("auto active sub-quests, and manually complete parent quest", () {
    QuestSystem.addQuestContainer(QuestSequence(id: Object(), children: [
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

    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    expect(q.status, QuestStatus.activated);
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    expect(q.children[0].status, QuestStatus.activated);
    expect(q.children[1].status, QuestStatus.activated);

    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c3));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.activated);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c4));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.completed);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    expect(q.status, QuestStatus.completed);
  });

  test("auto active sub-quests, and auto complete parent quest", () {
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
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

    final q = QuestSystem.getQuest<QuestSequence>(MyQuestSeqId.seq1)!;

    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c3));
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c4));

    expect(q.status, QuestStatus.completed);
  });

  test("json exporter", () {
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
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
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestId.q4, children: [
      Quest(
        id: MyQuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c5),
      )
    ]));

    final exporter = JsonExportVisitor();
    var data = QuestSystem.acceptVisitor(exporter);
    expect(
        jsonEncode(data),
        jsonEncode({
          "MyQuestSeqId.seq1": {"pointer": "MyQuestId.q1"},
          "MyQuestId.q1": {"status": 0},
          "MyQuestId.q2": {"status": 1},
          "MyQuestId.q3": {"status": 1},
          "MyQuestId.q4": {"pointer": "MyQuestId.q5"},
          "MyQuestId.q5": {"status": 1}
        }));
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    ct.dispatch(const QuestTriggerData(condition: MyQuestCondition.c3));
    data = QuestSystem.acceptVisitor(exporter);
    final matcher = {
      "MyQuestSeqId.seq1": {"pointer": null},
      "MyQuestId.q1": {"status": 2},
      "MyQuestId.q2": {"status": 2},
      "MyQuestId.q3": {"status": 2},
      "MyQuestId.q4": {"pointer": "MyQuestId.q5"},
      "MyQuestId.q5": {"status": 1}
    };
    expect(jsonEncode(data), jsonEncode(matcher));
  });
  test("json importer", () {
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
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

    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestId.q4, children: [
      Quest(
        id: MyQuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c5),
      )
    ]));
    final matcher = {
      "MyQuestSeqId.seq1": {"pointer": null},
      "MyQuestId.q1": {"status": 2},
      "MyQuestId.q2": {"status": 1},
      "MyQuestId.q3": {"status": 2},
      "MyQuestId.q4": {"pointer": "MyQuestId.q5"},
      "MyQuestId.q5": {"status": 1}
    };

    QuestSystem.acceptVisitor(JsonImportVisitor(matcher));

    var data = QuestSystem.acceptVisitor(JsonExportVisitor());
    expect(jsonEncode(data), jsonEncode(matcher));
  });
  // test("listener should be triggered when new sequences added", () async {});

  group("quest callback test", () {
    test("callback onTrigger", () {
      final onTriggerCallback = expectAsync0(() {}, count: 2);
      final onCompleteCallback = expectAsync0(() {}, count: 2);

      QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
        QuestGroup(
            id: MyQuestId.q1,
            triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
            completeChecker: QuestChecker.automate(),
            onTrigger: onTriggerCallback,
            onComplete: onCompleteCallback,
            children: [
              Quest.autoTrigger(
                id: MyQuestId.q2,
                completeChecker: QuestChecker.condition(MyQuestCondition.c2),
                onTrigger: onTriggerCallback,
                onComplete: onCompleteCallback,
              ),
            ]),
      ]));
      CustomTrigger.instance
          .dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
      CustomTrigger.instance
          .dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
    });
  });
  test("test listener callbacks", () {
    QuestSystem.addQuestContainer(QuestSequence(id: MyQuestSeqId.seq1, children: [
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
    ]));
    QuestSystem.listenerAll(expectAsync0(() {}, count: 3));
    CustomTrigger.instance
        .dispatch(const QuestTriggerData(condition: MyQuestCondition.c1));
    CustomTrigger.instance
        .dispatch(const QuestTriggerData(condition: MyQuestCondition.c2));
  });
}
