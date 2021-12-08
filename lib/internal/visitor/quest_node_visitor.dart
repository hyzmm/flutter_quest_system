import 'package:guidance_system/internal/quest.dart';

abstract class QuestNodeVisitor<T> {
  void visitQuestRoot(QuestRoot questRoot);

  T visitQuest(Quest quest);

  T visitQuestSequence(QuestSequence questSequence);

  T visitQuestGroup(QuestGroup questGroup);
}
