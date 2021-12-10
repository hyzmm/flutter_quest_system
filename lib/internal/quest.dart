import 'dart:developer';

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

class QuestRoot implements QuestNode {
  List<QuestSequence> quests;

  QuestRoot(this.quests);

  get length => quests.length;

  QuestSequence operator [](int index) => quests[index];

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestRoot(this);
  }

  void clear() => quests.clear();
}

/// [QuestSequence] 是一个串行执行的任务序列，与之相关的还有任务组，[Quest] 赋予 children 属性就是任务组
class QuestSequence with EventDispatcher<QuestSequence> implements QuestNode {
  final Object id;
  final List<Quest> quests;

  int progress = 0;

  // factory QuestSequence.fromJson(Map<String, dynamic> json) {
  //   return QuestSequence(id: id, quests: quests);
  // }

  QuestSequence({required this.id, required this.quests}) {
    GuidanceSystem.seqCache[id] = this;

    for (var i = 0, len = quests.length; i < len; i++) {
      GuidanceSystem.questCache[quests[i].id] = quests[i];

      if (quests[i] is QuestGroup) {
        for (var e in (quests[i] as QuestGroup).children) {
          GuidanceSystem.questCache[e.id] = e;
        }
      }
    }
  }

  Quest operator [](int index) {
    return quests[index];
  }

  void check(QuestTriggerData data) {
    /// Quests completed
    if (progress >= quests.length) return;

    final quest = quests[progress];
    quest.check(data);
    if (quest.status == QuestStatus.completed) {
      progress++;
      dispatch(this);
    }
  }

  int get totalProgress => quests.length;

  QuestStatus get status {
    if (progress >= quests.length) return QuestStatus.completed;
    return QuestStatus.activated;
  }

  // Map<String, dynamic> exportJson() {
  //   return {
  //     "id": id.toString(),
  //     "quests": quests.map((e) => e.exportJson()).toList(),
  //   };
  // }

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

  /// 创建一个子任务，当父任务激活时，此任务会自动激活
  /// 通常作为任务组的子任务出现
  /// 它的检查器始终返回 true，一旦被检查就会激活
  factory Quest.activatedByParent({
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

  onTrigger(Key uiKey) {}

  onProgress(double progress) {}

  onFinish() {}

  /// 检查任务是否激活或者完成
  void check(QuestTriggerData data) {
    switch (status) {
      case QuestStatus.inactive:
        if (triggerChecker.check(data)) {
          status = QuestStatus.activated;
          dispatch(this);
        }
        break;
      case QuestStatus.activated:
        if (completeChecker.check(data)) {
          status = QuestStatus.completed;
          dispatch(this);
          log("Complete quest $id", name: "GUIDANCE");
        }
        break;
      case QuestStatus.completed:
        break;
    }
  }

  // Map<String, dynamic> exportJson() {
  //   final Map<String, dynamic> json = {
  //     "id": id.toString(),
  //     "status": status.toString(),
  //   };
  //   if (children != null) {
  //     json["children"] = children!.map((c) => c.exportJson()).toList();
  //   }
  //   return json;
  // }

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

  /// 检查任务是否激活或者完成
  /// 此方法会递归调用自身，完成子任务检查
  @override
  void check(QuestTriggerData data) {
    // return true if sub quest's status changes
    bool _checkSubQuest(Quest q) {
      final oldStatus = q.status;
      q.check(data);
      final newStatus = q.status;
      return oldStatus != newStatus;
    }

    // Use a flag to trigger dispatch only once
    bool shouldDispatch = false;

    switch (status) {
      case QuestStatus.inactive:
        if (triggerChecker.check(data)) {
          status = QuestStatus.activated;
          // When a query be activated, its children will be activated too
          for (var q in children) {
            if (_checkSubQuest(q)) shouldDispatch = true;
          }
          shouldDispatch = true;
        }
        break;
      case QuestStatus.activated:
        // if this quest is a group, it must complete all sub quests, then complete itself
        bool childrenCompleted = true;
        if (children.isNotEmpty) {
          for (var q in children) {
            if (_checkSubQuest(q)) shouldDispatch = true;
            if (q.status != QuestStatus.completed) childrenCompleted = false;
          }
        }
        if (childrenCompleted && completeChecker.check(data)) {
          status = QuestStatus.completed;

          shouldDispatch = true;
          log("Complete quest $id", name: "GUIDANCE");
        }
        break;
      case QuestStatus.completed:
        break;
    }

    if (shouldDispatch) dispatch(this);
  }

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
