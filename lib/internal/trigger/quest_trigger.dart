import 'dart:developer';

import 'package:quest_system/internal/event_dispatcher.dart';

import '../quest_system.dart';

class TriggerDestroyedException implements Exception {}

/// 任务触发器的数据，虽然现在只有一个字段，但是不能去掉这一层封装，因为任务触发器的数据未来可能包含其他的字段
class QuestTriggerData {
  final Object condition;

  // Object? args;

  const QuestTriggerData({required this.condition});

  @override
  String toString() {
    return 'QuestTriggerData{condition: $condition}';
  }
}

/// [QuestTrigger] 是所有触发器的基类，预定义的只有两个子类，[RouteTrigger] 用于被路由自动触发的检查
/// [CustomTrigger] 用于其他手动触发的检查，如果想要对触发器进行分类或者封装，可以继承 [QuestTrigger]
abstract class QuestTrigger with EventDispatcher<QuestTriggerData> {
  @override
  void dispatch(QuestTriggerData data) {
    if (QuestSystem.verbose) log("QuestTrigger dispatch $data", name: "QUEST");
    super.dispatch(data);
  }
}
