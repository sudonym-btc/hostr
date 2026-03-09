const kPeriodicTaskIdentifier = 'com.sudonym.hostr.task.periodic';
const kOneOffTaskIdentifier = 'com.sudonym.hostr.task.oneoff';

const allBackgroundTaskIdentifiers = <String>[
  kPeriodicTaskIdentifier,
  kOneOffTaskIdentifier,
];

enum BackgroundTaskType { onchainOps, periodicSync }

extension BackgroundTaskTypeX on BackgroundTaskType {
  String get taskName => name;

  String get identifier => switch (this) {
    BackgroundTaskType.onchainOps => kOneOffTaskIdentifier,
    BackgroundTaskType.periodicSync => kPeriodicTaskIdentifier,
  };
}

BackgroundTaskType parseBackgroundTaskType(String taskName) {
  for (final type in BackgroundTaskType.values) {
    if (taskName == type.taskName || taskName == type.identifier) {
      return type;
    }
  }
  return BackgroundTaskType.periodicSync;
}
