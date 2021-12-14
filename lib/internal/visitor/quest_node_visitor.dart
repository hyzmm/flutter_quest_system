import 'package:quest_system/internal/quest.dart';

abstract class QuestNodeVisitor<T> {
  T visitQuestRoot(QuestRoot questRoot);

  T visitQuestSequence(QuestSequence questSequence);

  T visitQuestGroup(QuestGroup questGroup);

  T visitQuest(Quest quest);
}
