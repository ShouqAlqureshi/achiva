import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/network/cache_network.dart';

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationPlugin = FlutterLocalNotificationsPlugin();
  static final onClickNotification = BehaviorSubject<String>();

  // on tap notification
  static void onTapNotification(NotificationResponse notificationResponse) {
    onClickNotification.add(notificationResponse.payload!);
  }
  static Future init() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();
    final LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(
        defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);
    _flutterLocalNotificationPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:  onTapNotification,
        onDidReceiveBackgroundNotificationResponse: onTapNotification
    );
    }

  static Future<bool> requestExactAlarmPermission() async {
    final platform = const MethodChannel('dexterx.dev/flutter_local_notifications_plugin');
    final bool? result = await platform.invokeMethod<bool>('requestExactAlarmPermission');
    return result ?? false;
  }


  static Future showNotification({
      required String title,
      required String body,
      required String payload
  }) async{
      const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
      const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
      await _flutterLocalNotificationPlugin.show(
          0, title, body, notificationDetails,
          payload: payload);
    }

  static Future cancelNotification({
    required String taskName,
    required String goalName,
  }) async {

    await _flutterLocalNotificationPlugin.cancel(2, tag: taskName + goalName);

  }

  // to schedule a local notification
  static Future showScheduleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    tz.initializeTimeZones();
    await _flutterLocalNotificationPlugin.zonedSchedule(
        2,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        NotificationDetails(
            android: AndroidNotificationDetails(
                'channel 3', 'your channel name',
                tag: title + body,
                channelDescription: 'your channel description',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload);
  }

  static Future scheduleTaskDueNotification({
    required String taskName,
    required DateTime dueDate,
    required String goalName,
  }) async {
    tz.initializeTimeZones();

    final scheduledDate = dueDate.subtract(const Duration(hours: 1));

    final PermissionStatus notificationStatus =
    await Permission.notification.request();

    final PermissionStatus notification1Status =
    await Permission.scheduleExactAlarm.request();
    //  await requestExactAlarmPermission();
    final bool? permissionGranted = await _flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

      await _flutterLocalNotificationPlugin.zonedSchedule(
        // Use timestamp as unique ID
       2,
        'Task Due Soon',
        'Task "$taskName" will start soon',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_due_channel',
            'Task Due Notifications',
            channelDescription: 'Notifications for tasks that are due soon',
            importance: Importance.max,
            priority: Priority.high,
            tag: taskName + goalName,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
  }

  static Future scheduleTaskHourNotification({
    required String taskName,
    required DateTime dueDate,
    required String goalName,
  }) async {
    tz.initializeTimeZones();
    // Check if we have permission first
    final PermissionStatus notificationStatus =
    await Permission.notification.request();

    final PermissionStatus notification1Status =
    await Permission.scheduleExactAlarm.request();
  //  await requestExactAlarmPermission();
    final bool? permissionGranted = await _flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();


 //   if (permissionGranted ?? false) {
      await _flutterLocalNotificationPlugin.zonedSchedule(
        1,
        'Reminder',
        'Task "$taskName" from goal "$goalName" will start in 1 hour',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_due_channel',
            'Task Due Notifications',
            channelDescription: 'Notifications for tasks that are due soon',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  //}


}