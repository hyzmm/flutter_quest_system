import 'package:guidance_system/internal/event_dispatcher.dart';

class TriggerDestroyedException implements Exception {}

class QuestTriggerData {
  Object condition;
  Object? args;

  QuestTriggerData({required this.condition, this.args});
}

abstract class QuestTrigger with EventDispatcher<QuestTriggerData> {}
