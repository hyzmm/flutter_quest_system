import 'package:guidance_system/internal/trigger/quest_trigger.dart';
import 'package:guidance_system/internal/trigger/route_trigger.dart';

class QuestChecker {
  Object condition;

  Function(QuestTriggerData)? customChecker;

  QuestChecker({required this.condition, this.customChecker});

  factory QuestChecker.routeChecker(RouteCondition condition) {
    return QuestChecker(condition: condition);
  }

  /// 一旦被检查就会返回 true，通常用于子任务自动激活，或者父任务自动结束
  factory QuestChecker.autoActivate() {
    return QuestChecker(condition: Object(), customChecker: (_) => true);
  }

  bool check(QuestTriggerData data) {
    if (customChecker != null) {
      return customChecker!.call(data);
    } else {
      return condition == data.condition;
    }
  }
}
