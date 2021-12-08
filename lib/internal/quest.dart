import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:guidance_system/guidance_system.dart';
import 'package:guidance_system/internal/trigger/quest_trigger.dart';

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

/// [QuestSequence] 是一个串行执行的任务序列，与之相关的还有任务组，[Quest] 赋予 children 属性就是任务组
class QuestSequence with EventDispatcher<QuestSequence> {
  final Object id;
  final List<Quest> quests;

  int _pointer = 0;

  // factory QuestSequence.fromJson(Map<String, dynamic> json) {
  //   return QuestSequence(id: id, quests: quests);
  // }

  QuestSequence({required this.id, required this.quests}) {
    GuidanceSystem.seqCache[id] = this;

    for (var i = 0, len = quests.length; i < len; i++) {
      GuidanceSystem.questCache[quests[i].id] = quests[i];

      if (i + 1 < len) quests[i].next = quests[i + 1];

      quests[i].children?.forEach((e) {
        GuidanceSystem.questCache[e.id] = e;
      });
    }
  }

  Quest operator [](int index) {
    return quests[index];
  }

  void check(QuestTriggerData data) {
    /// Quests completed
    if (_pointer >= quests.length) return;

    final quest = quests[_pointer];
    quest.check(data);
    if (quest.status == QuestStatus.completed) {
      _pointer++;
      dispatch(this);
    }
  }

  int get progress => _pointer;

  int get totalProgress => quests.length;

  QuestStatus get status {
    if (_pointer >= quests.length) return QuestStatus.completed;
    return QuestStatus.activated;
  }

  Map<String, dynamic> exportJson() {
    return {
      "id": id.toString(),
      "quests": quests.map((e) => e.exportJson()).toList(),
    };
  }
}

class Quest with EventDispatcher<Quest> {
  Object id;

  QuestStatus status = QuestStatus.inactive;

  Quest? next;

  // Object data; // maybe used to store data that onTrigger produce

  List<Quest>? children;
  QuestChecker triggerChecker;

  QuestChecker completeChecker;

  Key? uiKey;

  Quest({
    required this.id,
    required this.triggerChecker,
    required this.completeChecker,
    this.children,
    this.uiKey,
  }) {
    // Maybe this quest is auto activated.
    if (triggerChecker.customChecker != null &&
        triggerChecker.customChecker!
            .call(QuestTriggerData(condition: Object()))) {
      status = QuestStatus.activated;
    }
  }

  /// 创建一个父任务，当子任务全部完成时，此任务会自动完成
  /// 通常作为任务组的父任务出现
  /// 它的检查器始终返回 true，一旦被检查就会激活
  factory Quest.completeByChildren({
    required id,
    required triggerChecker,
    required List<Quest> children,
    Key? uiKey,
  }) {
    return Quest(
      id: id,
      triggerChecker: triggerChecker,
      completeChecker: QuestChecker.autoActivate(),
      children: children,
      uiKey: uiKey,
    );
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
      triggerChecker: QuestChecker.autoActivate(),
      completeChecker: completeChecker,
      uiKey: uiKey,
    );
  }

  int get numCompletedChildQuests {
    if (children == null || children!.isEmpty) {
      return status == QuestStatus.completed ? 1 : 0;
    }

    // [progressInPercent] equals it's children complete percentage.
    var numFinished = 0;
    for (final e in children!) {
      if (e.status == QuestStatus.completed) numFinished++;
    }
    return numFinished;
  }

  int get numChildQuests {
    return children?.length ?? 0;
  }

  /// 任务完成率范围从 0~1，未完成为 0，已完成为 1，如果这个任务有子任务，则取决于子任务完成度
  /// 例如，三个子任务完成了一个，完成率为 1/3
  double get progressInPercent {
    // return 1 if the quest has completed itself.
    if (status == QuestStatus.completed) return 1;

    // check self's _status if no children
    if (children == null || children!.isEmpty) {
      return status == QuestStatus.completed ? 1 : 0;
    }

    // [progressInPercent] equals it's children complete percentage.
    return numCompletedChildQuests / children!.length;
  }

  onTrigger(Key uiKey) {}

  onProgress(double progress) {}

  onFinish() {}

  /// 检查任务是否激活或者完成
  /// 此方法会递归调用自身，完成子任务检查
  void check(QuestTriggerData data) {
    _check(QuestChecker checker) {
      if (checker.customChecker != null) {
        return checker.customChecker!.call(data);
      } else {
        return checker.condition == data.condition;
      }
    }

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
        if (_check(triggerChecker)) {
          status = QuestStatus.activated;
          // When a query be activated, its children will be activated too
          children?.forEach((q) {
            if (_checkSubQuest(q)) shouldDispatch = true;
          });
          shouldDispatch = true;
        }
        break;
      case QuestStatus.activated:
        // if this quest is a group, it must complete all sub quests, then complete itself
        bool childrenCompleted = true;
        if (children != null && children!.isNotEmpty) {
          for (var q in children!) {
            if (_checkSubQuest(q)) shouldDispatch = true;
            if (q.status != QuestStatus.completed) childrenCompleted = false;
          }
        }
        if (childrenCompleted && _check(completeChecker)) {
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

  Map<String, dynamic> exportJson() {
    final Map<String, dynamic> json = {
      "id": id.toString(),
      "status": status.toString(),
    };
    if (children != null) {
      json["children"] = children!.map((c) => c.exportJson()).toList();
    }
    return json;
  }
}
