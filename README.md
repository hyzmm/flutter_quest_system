为 Flutter 实现的基于任务的引导系统，也可以只作为任务系统使用。

## 介绍
下面的视频展示了 QuestSystem 的功能，这个 Demo 的源码在 example 里面。这里有两个任务，第一个任务有两个子任务，完成子任务后第一个任务才算完成。第二个任务是一个有两个任务的任务队列，完成后，第二个任务的 UI 会隐藏。视频的步骤是：

1. 点击「Quest 1 - 1」，弹出 BottomSheet，由路由关闭触发任务完成
2. 点击右下角按钮，由自定义动作完成「Quest 1 - 2」
3. 点击第二个任务的按钮，第一次点击完成任务序列的第一个任务后，开启第二个任务，再次点击完成，随后第二个任务全部完成，UI 根据任务状态自动隐藏。

https://user-images.githubusercontent.com/48704743/145536738-66f5146c-3e83-4b56-ac6f-b2bcc918e896.mov


引导可能会发生在任意功能模块内，且触发条件和完成条件各式各样，为了降低代码耦合和维护成本，这个 Package 设计一套低耦合的实现方式。

引导中的每个步骤称为任务，引导系统支持以下功能：

1. 可中断-恢复的任务
2. 任务组
3. 串行任务和并行任务
4. 任务数据的序列化和反序列化
5. 完全分离的代码配置
6. 提供 Widget 定制根据任务状态改变的 UI

![Flutter-QuestSystem](README.assets/Flutter-QuestSystem.jpg)

`QuestSystem` 由以下几个部分组成：

1. QuestSystem：用户入口，通过它配置和访问任务
2. Quest：提供诸如任务、任务组、任务序列等结构体
3. Trigger：任务触发器，触发后开始检查任务
4. QuestChecker：定义如何激活或者完成任务
5. Visitor：规定遍历任务树的方式，导入、导出和完成任务就是通过 visitor 进行的
6. Widget：提供 Flutter Widget 组件用于构建与任务相关的 UI

### 任务

任务树不能无限的嵌套下去，QuestSystem 添加任务的 API 是 `addSequence` ，参数类型是 `QuestSequnce`，一个任务序列可能是：

```
Quest 1
Quest 2
……
Quest n
```

这个任务序列是一个线性任务，执行完任务 1，任务 2 开始激活，完成任务 2 继续完成任务 3，以此类推。还有一个可能是：

```
QuestGroup 1
	Quest 1-1
  Quest 1-2
  ……
  Quest 1-n
Quest 2
……
```

QuestGroup 继承自 Quest，QuestSequnce 内的每个任务都可能是一个任务组，任务组只有完成了全部子任务才能完成自身，也就是上面的 Quest 2 完成前，必须完成 Quest 1-1 到 1-n，并且完成了 QuestGroup 1 自身。

Quest 模块中，几个类的分工如下：

- Quest：单项任务配置
- QuestGroup：可以有子任务，子任务全部完成，才能完成自身
- QuestSequence：QuestSystem 可以添加的任务序列，用来配置串行执行的任务。如果调用多次 `QuestSystem.addSequence` 可以配置多条并行执行的任务。

Quest 模块的结构和组合模式非常接近，QuestSystem 通过语义限定了或者 assert 限制了无限嵌套，主要是因为考虑到多层嵌套对于任务系统来说没有现实意义，并且增加了复杂度和理解成本。

### 触发器

触发器用于通知引导系统开始检查任务，有两个内置的触发器：RouteTrigger 和 CustomTrigger，前者通过 Flutter Navigator Observer 自动检查由路由触发的任务条件；后者用于其他需要手动触发的任务条件。在更庞大的业务场景中，可以继承 QuestTrigger 来划分不同的触发器，而不是全部使用  CustomTrigger。

对于自动触发的检查器可以使用 `QuestChecker.automate()`，`Quest.autoTrigger`  就是通过这种方式自动激活任务的。

### ID

无论是 Quest、QuestGroup 还是 QuestSequence 都有一个 id 参数，类型是 Object，这表示它能接受任意参数，不过实际上大多数情况，这个 id 都是一个枚举值。id 的作用是用来获取任务，或者是序列化成数据时用到的，如果不需要这两个功能，甚至可以给 id 传入 `Object()`，实际上 id 用到的知识它的 `toString`，在「高级用法」中能看到用 Class 实例作为 id 的情况。

## 使用

添加内置触发器，并且把路由触发器加入到 Navigator Observer 中：

```dart
QuestSystem.addTrigger(RouteTrigger.instance);
QuestSystem.addTrigger(CustomTrigger.instance);

...
MaterialApp(
  navigatorObservers: [
    RouteTrigger.instance,
  ],
)
...
```

配置任务：

```dart
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(...),
  Quest(...),
]));
```

最后使用 `quest.on(...)`  或者 QuestBuilder 使用任务：

```dart
QuestSystem.getQuest(id)!.on((quest) {
  print(quest.status);
});
// or
QuestBuilder<QuestGroup>.id(id,
  builder: (QuestGroup? quest) {
	return Text("${quest!.progress}/${quest.length} - ${quest.status.description}");
})
```

## 用例

创建两条简单的任务序列，在 Q1 完成后，激活 Q2，完成 Q2 后，任务全部完成。

```
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(
    id: QuestId.q1,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  ),
  Quest(
    id: QuestId.q2,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  )
]));
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(
    id: QuestId.q3,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  )
]));
```

## 暂不支持

这些不支持的特性是因为当前不需要用到这些特性，实际上还是留有了扩展空间。

1. 细化的任务进度，例如「击杀 10 个敌人」
2. 带蒙层的操作引导
