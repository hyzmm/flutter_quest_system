import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidance_system/internal/checker.dart';
import 'package:guidance_system/internal/guidance_system.dart';
import 'package:guidance_system/internal/quest.dart';
import 'package:guidance_system/internal/trigger/custom_trigger.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/visitor/json_export_visitor.dart';
import 'package:guidance_system/internal/visitor/json_import_visitor.dart';

enum QuestCondition { c1, c2, c3, c4, c5, c6 }

enum QuestSeqId {
  seq1,
  seq2,
}
enum QuestId {
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
    GuidanceSystem.addTrigger(ct);
  });

  setUp(() {
    GuidanceSystem.root.clear();
    GuidanceSystem.questCache.clear();
    GuidanceSystem.seqCache.clear();
  });

  test("single task queue", () {
    GuidanceSystem.addSequence(QuestSequence(id: Object(), quests: [
      Quest(
        id: QuestId.q1,
        triggerChecker: QuestChecker.condition(QuestCondition.c1),
        completeChecker: QuestChecker.condition(QuestCondition.c2),
      ),
      Quest(
        id: QuestId.q2,
        triggerChecker: QuestChecker.condition(QuestCondition.c1),
        completeChecker: QuestChecker.condition(QuestCondition.c2),
      )
    ]));
    GuidanceSystem.addSequence(QuestSequence(id: Object(), quests: [
      Quest(
        id: QuestId.q3,
        triggerChecker: QuestChecker.condition(QuestCondition.c1),
        completeChecker: QuestChecker.condition(QuestCondition.c2),
      )
    ]));

    final q1 = GuidanceSystem.getQuest(QuestId.q1)!;
    final q2 = GuidanceSystem.getQuest(QuestId.q2)!;
    final q3 = GuidanceSystem.getQuest(QuestId.q3)!;

    expect(q1.status, QuestStatus.inactive);
    expect(q3.status, QuestStatus.inactive);
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c1));
    expect(q1.status, QuestStatus.activated);
    expect(q3.status, QuestStatus.activated);
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c2));
    expect(q1.status, QuestStatus.completed);
    expect(q3.status, QuestStatus.completed);

    // quest checker should not effect the inactive quests.
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
    expect(q2.status, QuestStatus.inactive);
  });

  test("auto active sub-quests, and manually complete parent quest", () {
    GuidanceSystem.addSequence(QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: QuestId.q4,
          triggerChecker: QuestChecker.condition(QuestCondition.c1),
          completeChecker: QuestChecker.condition(QuestCondition.c2),
          children: [
            Quest.autoTrigger(
              id: QuestId.q5,
              completeChecker: QuestChecker.condition(QuestCondition.c3),
            ),
            Quest.autoTrigger(
              id: QuestId.q6,
              completeChecker: QuestChecker.condition(QuestCondition.c4),
            ),
          ])
    ]));

    final q = GuidanceSystem.getQuest<QuestGroup>(QuestId.q4)!;

    ct.dispatch(QuestTriggerData(condition: QuestCondition.c1));
    expect(q.status, QuestStatus.activated);
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    expect(q.children[0].status, QuestStatus.activated);
    expect(q.children[1].status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: QuestCondition.c3));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.activated);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: QuestCondition.c4));
    expect(q.children[0].status, QuestStatus.completed);
    expect(q.children[1].status, QuestStatus.completed);
    expect(q.status, QuestStatus.activated);

    ct.dispatch(QuestTriggerData(condition: QuestCondition.c2));
    expect(q.status, QuestStatus.completed);
  });

  test("auto active sub-quests, and auto complete parent quest", () {
    GuidanceSystem.addSequence(QuestSequence(id: Object(), quests: [
      QuestGroup(
          id: QuestId.q1,
          triggerChecker: QuestChecker.condition(QuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: QuestId.q5,
              completeChecker: QuestChecker.condition(QuestCondition.c3),
            ),
            Quest.autoTrigger(
              id: QuestId.q6,
              completeChecker: QuestChecker.condition(QuestCondition.c4),
            ),
          ])
    ]));

    final q = GuidanceSystem.root[0];

    ct.dispatch(QuestTriggerData(condition: QuestCondition.c1));
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c2));
    expect(
      q.status != QuestStatus.completed,
      true,
      reason: "before the quest group completed, "
          "you must complete all its sub quests",
    );
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c3));
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c4));

    expect(q.status, QuestStatus.completed);
  });

  test("json exporter", () {
    GuidanceSystem.addSequence(QuestSequence(id: QuestSeqId.seq1, quests: [
      QuestGroup(
          id: QuestId.q1,
          triggerChecker: QuestChecker.condition(QuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: QuestId.q2,
              completeChecker: QuestChecker.condition(QuestCondition.c2),
            ),
          ]),
      Quest(
        id: QuestId.q3,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(QuestCondition.c3),
      ),
    ]));
    GuidanceSystem.addSequence(QuestSequence(id: QuestId.q4, quests: [
      Quest(
        id: QuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(QuestCondition.c5),
      )
    ]));

    final exporter = JsonExportVisitor();
    var data = GuidanceSystem.root.accept(exporter);
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
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c1));
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c2));
    ct.dispatch(QuestTriggerData(condition: QuestCondition.c3));
    data = GuidanceSystem.root.accept(exporter);
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
    GuidanceSystem.addSequence(QuestSequence(id: QuestSeqId.seq1, quests: [
      QuestGroup(
          id: QuestId.q1,
          triggerChecker: QuestChecker.condition(QuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: QuestId.q2,
              completeChecker: QuestChecker.condition(QuestCondition.c2),
            ),
          ]),
      Quest(
        id: QuestId.q3,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(QuestCondition.c3),
      ),
    ]));

    GuidanceSystem.addSequence(QuestSequence(id: QuestId.q4, quests: [
      Quest(
        id: QuestId.q5,
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(QuestCondition.c5),
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

    GuidanceSystem.root.accept(JsonImportVisitor(matcher));

    var data = GuidanceSystem.root.accept(JsonExportVisitor());
    expect(jsonEncode(data), jsonEncode(matcher));
  });
}
