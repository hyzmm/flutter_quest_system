import 'package:guidance_system/internal/quest.dart';

abstract class QuestNodeVisitor {
  void visitQuest(Quest quest);

  void visitQuestSequence(QuestSequence questSequence);

  void visitQuestRoot(QuestRoot questRoot);
}
