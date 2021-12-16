import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';
import 'package:quest_system/internal/visitor/dispatch_visitor.dart';
import 'package:quest_system/internal/visitor/dispose_visitor.dart';
import 'package:quest_system/internal/visitor/quest_check_visitor.dart';
import 'package:quest_system/internal/visitor/quest_node_visitor.dart';
import 'package:quest_system/quest_system.dart';

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

/// [QuestId] 用于复杂的条件定义，与 [QuestCondition] 仅有语义上的区分
@immutable
class QuestId {
  /// enum collection
  final List<Object> segments;

  const QuestId(this.segments);

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! QuestId) return false;
    if (segments.length != other.segments.length) return false;

    for (int i = segments.length - 1; i >= 0; i--) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  @override
  String toString() => segments.join();
}

/// [QuestCondition] 用于复杂的条件定义，与 [QuestId] 仅有语义上的区分
class QuestCondition extends QuestId {
  const QuestCondition(List<Object> segments) : super(segments);
}

abstract class QuestNode {
  void accept(QuestNodeVisitor visitor);
}

class QuestRoot with EventDispatcher<QuestRoot> implements QuestNode {
  List<QuestSequence> quests;

  QuestRoot(this.quests);

  get length => quests.length;

  void add(QuestSequence sequence) {
    quests.add(sequence);
    sequence._subscription = sequence.on((_) => dispatch(this));
  }

  void addAll(Iterable<QuestSequence> sequences) {
    sequences.forEach(add);
  }

  void remove(QuestSequence seq) {
    quests.remove(seq);
    seq._subscription?.cancel();
    seq.accept(const DispatchVisitor());
  }

  void clear() {
    accept(const DisposeVisitor());
    quests.clear();
  }

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestRoot(this);
  }

  QuestSequence operator [](int index) => quests[index];
}

/// [QuestSequence] 是一个串行执行的任务序列，与之相关的还有任务组，[Quest] 赋予 children 属性就是任务组
/// 如果调用多次 [QuestSystem.addSequence] 可以配置多条并行执行的任务
class QuestSequence with EventDispatcher<QuestSequence> implements QuestNode {
  final Object id;
  final List<Quest> quests;

  int progress = 0;

  int get totalProgress => quests.length;

  QuestStatus get status {
    if (progress >= quests.length) return QuestStatus.completed;
    return QuestStatus.activated;
  }

  StreamSubscription? _subscription;

  QuestSequence({required this.id, required this.quests}) {
    QuestSystem.seqCache[id] = this;

    for (var i = 0, len = quests.length; i < len; i++) {
      QuestSystem.questCache[quests[i].id] = quests[i];

      if (quests[i] is QuestGroup) {
        for (var e in (quests[i] as QuestGroup).children) {
          QuestSystem.questCache[e.id] = e;
        }
      }

      quests[i]._subscription = quests[i].on((_) => dispatch(this));
    }
  }

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestSequence(this);
  }

  void disconnectListeners() {
    for (var e in quests) {
      e._subscription?.cancel();
    }
  }

  Quest operator [](int index) {
    return quests[index];
  }
}

class Quest with EventDispatcher<Quest> implements QuestNode {
  Object id;

  QuestStatus status = QuestStatus.inactive;

  QuestChecker triggerChecker;

  QuestChecker completeChecker;

  StreamSubscription? _subscription;

  VoidCallback? onTrigger;

  //
  // onProgress(double progress) {}
  //
  VoidCallback? onComplete;

  Quest({
    required this.id,
    required this.triggerChecker,
    required this.completeChecker,
    this.onTrigger,
    this.onComplete,
    // this.uiKey,
  }) {
    accept(const QuestCheckVisitor(QuestTriggerData(condition: Object())));
  }

  /// 创建一个自动激活的子任务
  factory Quest.autoTrigger({
    required id,
    required completeChecker,
    VoidCallback? onTrigger,
    VoidCallback? onComplete,
  }) {
    return Quest(
      id: id,
      triggerChecker: QuestChecker.automate(),
      completeChecker: completeChecker,
      onTrigger: onTrigger,
      onComplete: onComplete,
    );
  }

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuest(this);
  }
}

/// 任务组只有完成了全部子任务才能完成自身
class QuestGroup extends Quest {
  List<Quest> children;

  QuestGroup({
    required Object id,
    required QuestChecker triggerChecker,
    required QuestChecker completeChecker,
    required this.children,
    VoidCallback? onTrigger,
    VoidCallback? onComplete,
    Key? uiKey,
  })  : assert((() => children.every((e) => e.runtimeType == Quest))(),
            "The children of QuestGroup must be Quest"),
        super(
            id: id,
            triggerChecker: triggerChecker,
            completeChecker: completeChecker,
            onTrigger: onTrigger,
            onComplete: onComplete);

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

  void disconnectListeners() {
    for (var e in children) {
      e._subscription?.cancel();
    }
  }

  Quest operator [](int i) => children[i];
}
