import 'dart:async';

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

abstract class QuestNode<T> with EventDispatcher<T> {
  final Object id;
  StreamSubscription? _subscription;

  QuestNode(this.id);

  QuestStatus get status;

  set status(QuestStatus v);

  void accept(QuestNodeVisitor visitor);
}

/// [QuestContainer] 表示保存多个任务的容器，实现它的接口可能是串行任务 [QuestSequence] 或者 任务组 [QuestGroup]
abstract class QuestContainer extends QuestNode {
  final List<QuestNode> children;

  QuestContainer({required Object id, required this.children}) : super(id);
}

class QuestRoot with EventDispatcher {
  List<QuestContainer> quests;

  QuestRoot(this.quests);

  get length => quests.length;

  void add(QuestContainer container) {
    quests.add(container);
    container._subscription = container.on((_) => dispatch(this));
  }

  void addAll(Iterable<QuestContainer> sequences) {
    sequences.forEach(add);
  }

  void remove(QuestContainer container) {
    quests.remove(container);
    container._subscription?.cancel();
    container.accept(const DispatchVisitor());
  }

  void clear() {
    accept(const DisposeVisitor());
    quests.clear();
  }

  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestRoot(this);
  }

  QuestContainer operator [](int index) => quests[index];
}

/// [QuestSequence] 是一个串行执行的任务序列，与之相关的还有任务组，[Quest] 赋予 children 属性就是任务组
/// 如果调用多次 [QuestSystem.addQuestContainer] 可以配置多条并行执行的任务
class QuestSequence extends QuestContainer {
  int progress = 0;

  int get totalProgress => children.length;

  @override
  QuestStatus get status {
    if (progress >= children.length) return QuestStatus.completed;
    return QuestStatus.activated;
  }

  @override
  set status(QuestStatus v) {
    throw "cannot set status on QuestSequence";
  }

  QuestSequence({required Object id, required List<QuestNode> children})
      : super(
          id: id,
          children: children,
        ) {
    QuestSystem.questMap[id] = this;

    for (var i = 0, len = children.length; i < len; i++) {
      QuestSystem.questMap[children[i].id] = children[i];

      if (children[i] is QuestGroup) {
        for (var e in (children[i] as QuestGroup).children) {
          QuestSystem.questMap[e.id] = e;
        }
      }

      children[i]._subscription = children[i].on((_) => dispatch(this));
    }
  }

  @override
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestSequence(this);
  }

  void disconnectListeners() {
    for (var e in children) {
      e._subscription?.cancel();
    }
  }

  QuestNode operator [](int index) {
    return children[index];
  }
}

/// [Quest] 用来配置单项任务，表示一个非常具体的任务，不可再细分，
/// 它会作为 [QuestGroup] 或者 [QuestSequence] 的子节点出现。例如被配置为「点击某个按钮」。
/// `triggerChecker` 是用来检查能否激活还未激活的任务，
/// `completeChecker` 则用来检查能否完成一个已激活的任务。
class Quest extends QuestNode<Quest> {
  @override
  QuestStatus status = QuestStatus.inactive;

  QuestChecker triggerChecker;

  QuestChecker completeChecker;

  VoidCallback? onTrigger;

  //
  // onProgress(double progress) {}
  //
  VoidCallback? onComplete;

  Quest({
    required Object id,
    required this.triggerChecker,
    required this.completeChecker,
    this.onTrigger,
    this.onComplete,
    // this.uiKey,
  }) : super(id) {
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
class QuestGroup extends QuestContainer {
  @override
  QuestStatus status = QuestStatus.inactive;

  QuestChecker triggerChecker;
  QuestChecker completeChecker;

  VoidCallback? onTrigger;
  VoidCallback? onComplete;

  QuestGroup({
    required Object id,
    required this.triggerChecker,
    required this.completeChecker,
    required List<Quest> children,
    this.onTrigger,
    this.onComplete,
  })  : assert((() => children.every((e) => e.runtimeType == Quest))(),
            "The children of QuestGroup must be Quest"),
        super(
          id: id,
          children: children,
        ) {
    QuestSystem.questMap[id] = this;
    for (var i = 0, len = children.length; i < len; i++) {
      QuestSystem.questMap[children[i].id] = children[i];
    }
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
  dynamic accept(QuestNodeVisitor visitor) {
    return visitor.visitQuestGroup(this);
  }

  /// 添加一个任务，注意，如果父任务已经完成，刚添加的任务不会被完成，因为它不会被检查
  void add(Quest quest) {
    QuestSystem.questMap[quest.id] = quest;
    final existingIndex = children.indexWhere((e) => e.id == quest.id);
    if (existingIndex == -1) {
      children.add(quest);
    } else {
      children[existingIndex] = quest;
    }
    dispatch(this);
  }

  void remove(Quest quest) {
    dispatch(this);
    QuestSystem.questMap.remove(quest.id);
    children.remove(quest);
  }

  void disconnectListeners() {
    for (var e in children) {
      e._subscription?.cancel();
    }
  }

  Quest operator [](int i) => children[i] as Quest;
}
