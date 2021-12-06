import 'package:example/quest.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:guidance_system/guidance_system.dart';

const routeQ1 = "/routeQ1";
const routeQ2 = "/routeQ2";

void main() {
  // First step: add quest triggers
  GuidanceSystem.instance.addTrigger(RouteTrigger.instance);
  GuidanceSystem.instance.addTrigger(CustomTrigger.instance);

  // Second step: add quest to guidance system
  initQuests();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      navigatorObservers: [
        RouteTrigger.instance,
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Example"),
      ),
      floatingActionButton: ElevatedButton(
          onPressed: () {
            // Fourth step: trigger some conditions
            CustomTrigger.instance
                .dispatch(QuestTriggerData(condition: QuestCondition.c3));
          },
          child: const Text("Press me to complete Quest 2")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            buildQ1Box(context),
            buildQ2Box(),
          ],
        ),
      ),
    );
  }

  Widget buildQ1Box(BuildContext context) {
    return Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quest 1",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  // Third step: listen to quest status change
                  QuestBuilder(
                      questId: QuestId.q1,
                      builder: (quest) {
                        return Text(
                            "${quest!.numCompletedChildQuests}/${quest.numChildQuests} - ${quest.status.description}");
                      })
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [QuestId.q2, QuestId.q3]
                      .map((qId) => QuestBuilder(
                          questId: qId,
                          builder: (quest) {
                            return TextButton(
                              onPressed: qId == QuestId.q3
                                  ? null
                                  : () {
                                      Get.bottomSheet(
                                          SizedBox(
                                              height: context.heightTransformer(
                                                  dividedBy: 0.6),
                                              child: const Card(
                                                  child: Center(
                                                child: Text(
                                                    "Close this window to complete quest 2"),
                                              ))),
                                          settings: const RouteSettings(
                                              name: routeQ1));
                                    },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(qId.title),
                                  const SizedBox(width: 8),
                                  Text(quest?.status.description ?? "NotFound"),
                                ],
                              ),
                            );
                          }))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQ2Box() {
    return QuestSequenceBuilder(
        questId: QuestId.seq2,
        builder: (seq) {
          if (seq == null) return const Text("Quest Not Found");
          if (seq.status == QuestStatus.completed) return const SizedBox();

          return Card(
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(QuestId.seq2.title,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("${seq.progress}/${seq.totalProgress}"),
                      Text(seq.status.description),
                    ],
                  ),

                  // Quest.autoTrigger todo
                  const SizedBox(height: 8),
                  const Text(
                      "I will disappear after completed, Press the button twice to compete the quest sequence."),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () {
                        Get.to(() => Quest2Page(), routeName: routeQ2);
                      },
                      child: const Text("Press me")),
                ],
              ),
            ),
          );
        });
  }
}

class Quest2Page extends StatefulWidget {
  const Quest2Page({Key? key}) : super(key: key);

  @override
  _Quest2PageState createState() => _Quest2PageState();
}

class _Quest2PageState extends State<Quest2Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quest 2")),
      body: Center(child: Text("Back to complete quest 2")),
    );
  }
}
