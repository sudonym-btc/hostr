import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const simplePeriodic1HourTask = "com.sudonym.hostr.sync.android.periodic";
const iOSBackgroundAppRefresh = "com.sudonym.hostr.sync.ios.fetch";
const iOSBackgroundProcessingTask = "com.sudonym.hostr.sync.ios.processing";

final List<String> allTasks = [
  simplePeriodic1HourTask,
  iOSBackgroundAppRefresh,
  iOSBackgroundProcessingTask,
];

class BackgroundTasks extends StatefulWidget {
  @override
  _BackgroundTasksState createState() => _BackgroundTasksState();
}

class _BackgroundTasksState extends State<BackgroundTasks> {
  bool workmanagerInitialized = false;
  String _prefsString = "empty";
  int _selectedFrequency = 15; // Default to 15 minutes

  @override
  Widget build(BuildContext context) {
    return CustomPadding.sm(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            "Plugin initialization",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          FilledButton(
            child: Text(
              AppLocalizations.of(context)!.startFlutterBackgroundService,
            ),
            onPressed: () async {
              if (Platform.isIOS) {
                final status = await Permission.backgroundRefresh.status;
                if (status != PermissionStatus.granted) {
                  _showNoPermission(context, status);
                  return;
                }
              }
              if (!workmanagerInitialized) {
                try {
                  await Workmanager().initialize(callbackDispatcher);
                } catch (e) {
                  print('Error initializing Workmanager: $e');
                  return;
                }
                setState(() => workmanagerInitialized = true);
              }
              print('WorkManager already initialized');
            },
          ),
          Gap.vertical.sm(),
          Text(
            "Register task",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gap.vertical.sm(),
          Text(
            "Register periodic task (android only)",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gap.vertical.md(),
          Text(
            "Test Periodic Task with UPDATE Policy (Android)",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            "Demonstrates issue #622 fix - changing frequency updates the existing task",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Gap.vertical.sm(),
          if (Platform.isAndroid) ...[
            Row(
              children: [
                Text(AppLocalizations.of(context)!.frequencyLabel),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedFrequency,
                    items: [
                      DropdownMenuItem(
                        value: 15,
                        child: Text(AppLocalizations.of(context)!.minutes15),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text(AppLocalizations.of(context)!.minutes30),
                      ),
                      DropdownMenuItem(
                        value: 60,
                        child: Text(AppLocalizations.of(context)!.hour1),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],

          Gap.vertical.md(),
          // Currently we cannot provide frequency for iOS, hence it will be
          // minimum 15 minutes after which iOS will reschedule
          FilledButton(
            child: Text(
              AppLocalizations.of(
                context,
              )!.registerPeriodicBackgroundAppRefreshIos,
            ),
            onPressed: Platform.isIOS
                ? () async {
                    if (!workmanagerInitialized) {
                      _showNotInitialized();
                      return;
                    }
                    await Workmanager().registerPeriodicTask(
                      iOSBackgroundAppRefresh,
                      iOSBackgroundAppRefresh,
                      initialDelay: Duration(seconds: 0),
                      inputData: <String, dynamic>{}, //ignored on iOS
                    );
                  }
                : null,
          ),

          // This task runs only once, to perform a time consuming task at
          // a later time decided by iOS.
          // Processing tasks run only when the device is idle. iOS might
          // terminate any running background processing tasks when the
          // user starts using the device.
          FilledButton(
            child: Text(
              AppLocalizations.of(context)!.registerBackgroundProcessingTaskIos,
            ),
            onPressed: Platform.isIOS
                ? () async {
                    if (!workmanagerInitialized) {
                      _showNotInitialized();
                      return;
                    }
                    await Workmanager().registerProcessingTask(
                      iOSBackgroundProcessingTask,
                      iOSBackgroundProcessingTask,
                      initialDelay: Duration(seconds: 0),
                    );
                  }
                : null,
          ),
          Gap.vertical.sm(),
          Text(
            "Task cancellation",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancelAll),
            onPressed: () async {
              await Workmanager().cancelAll();
              print('Cancel all tasks completed');
            },
          ),
          Gap.vertical.md(),
          FilledButton(
            child: Text(AppLocalizations.of(context)!.refreshStats),
            onPressed: _refreshStats,
          ),
          Gap.vertical.sm(),
          SingleChildScrollView(
            child: Text(
              'Task run stats:\n'
              '${workmanagerInitialized ? '' : 'Workmanager not initialized'}'
              '\n$_prefsString',
            ),
          ),
        ],
      ),
    );
  }

  // Refresh/get saved prefs
  void _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    _prefsString = '';
    for (final task in allTasks) {
      _prefsString = '$_prefsString \n$task:\n${prefs.getString(task)}\n';
    }

    if (Platform.isIOS) {
      Workmanager().printScheduledTasks();
    }

    setState(() {});
  }

  void _showNotInitialized() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.workmanagerNotInitialized),
          content: Text(
            AppLocalizations.of(context)!.workmanagerNotInitializedMessage,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showNoPermission(BuildContext context, PermissionStatus hasPermission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.noPermission),
          content: Text(
            'Background app refresh is disabled, please enable in '
            'App settings. Status ${hasPermission.name}',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
