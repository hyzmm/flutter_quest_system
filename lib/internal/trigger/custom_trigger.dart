import 'package:quest_system/internal/trigger/quest_trigger.dart';

/// 使用 [CustomTrigger.instance.dispatch] 触发自定义条件
class CustomTrigger extends QuestTrigger {
  static late CustomTrigger instance = CustomTrigger();
}
