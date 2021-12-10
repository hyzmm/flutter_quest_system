import 'package:flutter/foundation.dart';
import 'package:guidance_system/guidance_system.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/visitor/quest_node_visitor.dart';

import 'checker.dart';
import 'event_dispatcher.dart';

enum QuestStatus {
  inactive,
  activated,
  completed,
}

extension QuestStatusExtension on QuestStatus {
  String get description {
    switch (this) {
      case QuestStatus.inactive:
        return "Inactive";
      case QuestStatus.activated:
        return "Activated";
      case QuestStatus.completed:
        return "Completed";
    }
  }
}

abstract class QuestNode {
  void accept(QuestNodeVisitor visitor);
}

class QuestRoot with EventDispatcher<QuestRoot> implements QuestNode {
  List<QuestSequence> quests;

  QuestRoot(this.quests);

  get length => quests.length;

  QuestSequence operator [](int index) => quests[index];

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestRoot(this);
  }

  void add(QuestSequence sequence) {
    quests.add(sequence);
    sequence.on((_) => dispatch(this));
  }

  void addAll(Iterable<QuestSequence> sequences) {
    sequences.forEach(add);
  }

  void clear() => quests.clear();
}

/// [QuestSequence] 是一个串行执行的任务序列，与之相关的还有任务组，[Quest] 赋予 children 属性就是任务组
class QuestSequence with EventDispatcher<QuestSequence> implements QuestNode {
  final Object id;
  final List<Quest> quests;

  int progress = 0;

  QuestSequence({required this.id, required this.quests}) {
    GuidanceSystem.seqCache[id] = this;

    for (var i = 0, len = quests.length; i < len; i++) {
      GuidanceSystem.questCache[quests[i].id] = quests[i];

      if (quests[i] is QuestGroup) {
        for (var e in (quests[i] as QuestGroup).children) {
          GuidanceSystem.questCache[e.id] = e;
        }
      }

      quests[i].on((_) => dispatch(this));
    }
  }

  Quest operator [](int index) {
    return quests[index];
  }

  int get totalProgress => quests.length;

  QuestStatus get status {
    if (progress >= quests.length) return QuestStatus.completed;
    return QuestStatus.activated;
  }

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestSequence(this);
  }
}

class Quest with EventDispatcher<Quest> implements QuestNode {
  Object id;

  QuestStatus status = QuestStatus.inactive;

  QuestChecker triggerChecker;

  QuestChecker completeChecker;

  Key? uiKey;

  Quest({
    required this.id,
    required this.triggerChecker,
    required this.completeChecker,
    this.uiKey,
  }) {
    // Maybe this quest is auto activated.
    if (triggerChecker.customChecker != null &&
        triggerChecker.customChecker!
            .call(QuestTriggerData(condition: Object()))) {
      status = QuestStatus.activated;
    }
  }

  /// 创建一个自动激活的子任务
  factory Quest.autoTrigger({
    required id,
    required completeChecker,
    Key? uiKey,
  }) {
    return Quest(
      id: id,
      triggerChecker: QuestChecker.automate(),
      completeChecker: completeChecker,
      uiKey: uiKey,
    );
  }

  // onTrigger(Key uiKey) {}
  //
  // onProgress(double progress) {}
  //
  // onFinish() {}

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuest(this);
  }
}

class QuestGroup extends Quest {
  List<Quest> children;

  QuestGroup({
    required Object id,
    required QuestChecker triggerChecker,
    required QuestChecker completeChecker,
    required this.children,
    Key? uiKey,
  }) : super(
            id: id,
            triggerChecker: triggerChecker,
            completeChecker: completeChecker);

  /// 任务完成率范围从 0~1，未完成为 0，已完成为 1，如果这个任务有子任务，则取决于子任务完成度
  /// 例如，三个子任务完成了一个，完成率为 1/3
  double get progressInPercent {
    // return 1 if the quest has completed itself.
    if (status == QuestStatus.completed) return 1;

    // [progressInPercent] equals it's children complete percentage.
    return progress / children.length;
  }

  int get progress {
    // [progressInPercent] equals it's children complete percentage.
    var numFinished = 0;
    for (final e in children) {
      if (e.status == QuestStatus.completed) numFinished++;
    }
    return numFinished;
  }

  int get length => children.length;

  @override
  accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestGroup(this);
  }

  Quest operator [](int i) => children[i];
}
