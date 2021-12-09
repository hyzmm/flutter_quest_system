import 'package:guidance_system/internal/trigger/quest_trigger.dart';

class QuestChecker {
  Object? condition;

  Function(QuestTriggerData)? customChecker;

  QuestChecker.condition(this.condition);

  QuestChecker.custom(Function(QuestTriggerData) func) : customChecker = func;

  //
  // factory QuestChecker.routeChecker(RouteCondition condition) {
  //   return QuestChecker.condition(condition);
  // }

  /// 自动激活或者完成
  factory QuestChecker.automate() {
    return QuestChecker.custom((_) => true);
  }

  bool check(QuestTriggerData data) {
    if (customChecker != null) {
      return customChecker!.call(data);
    } else {
      return condition == data.condition;
    }
  }
}
