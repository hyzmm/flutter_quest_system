import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_system/internal/checker.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/internal/visitor/json_export_visitor.dart';

import 'quest_system_test.dart';

@immutable
class CustomQuestId {
  final String id;

  const CustomQuestId(this.id);

  @override
  bool operator ==(Object other) => other is CustomQuestId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => "CustomQuestId-" + id;
}

main() {
  late CustomTrigger ct;

  setUpAll(() {
    ct = CustomTrigger.instance;
    QuestSystem.addTrigger(ct);
  });

  setUp(() {
    QuestSystem.clear();
    QuestSystem.questCache.clear();
    QuestSystem.seqCache.clear();
  });

  test("custom quest id", () {
    QuestSystem.addSequence(
        QuestSequence(id: const CustomQuestId("a"), quests: [
      QuestGroup(
          id: const CustomQuestId("b"),
          triggerChecker: QuestChecker.condition(MyQuestCondition.c1),
          completeChecker: QuestChecker.automate(),
          children: [
            Quest.autoTrigger(
              id: const CustomQuestId("c"),
              completeChecker: QuestChecker.condition(MyQuestCondition.c2),
            ),
          ]),
      Quest(
        id: const CustomQuestId("d"),
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c3),
      ),
    ]));

    QuestSystem.addSequence(
        QuestSequence(id: const CustomQuestId("e"), quests: [
      Quest(
        id: const CustomQuestId("f"),
        triggerChecker: QuestChecker.automate(),
        completeChecker: QuestChecker.condition(MyQuestCondition.c5),
      )
    ]));
    // final matcher = {
    //   "QuestSeqId.seq1": {"pointer": null},
    //   "QuestId.q1": {"status": 2},
    //   "QuestId.q3": {"status": 2},
    //   "QuestId.q4": {"pointer": "QuestId.q5"},
    //   "QuestId.q5": {"status": 1}
    // };
    //
    // GuidanceSystem.root.accept(JsonImportVisitor(matcher));

    var data = QuestSystem.acceptVisitor(JsonExportVisitor());
    expect(jsonEncode(data), jsonEncode({
      "CustomQuestId-a": {"pointer": "CustomQuestId-b"},
      "CustomQuestId-b": {"status": 0},
      "CustomQuestId-c": {"status": 1},
      "CustomQuestId-d": {"status": 1},
      "CustomQuestId-e": {"pointer": "CustomQuestId-f"},
      "CustomQuestId-f": {"status": 1}
    }));
  });
}
