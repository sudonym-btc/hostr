import 'dart:io';

String? platformEnvironment(String key) => Platform.environment[key];

bool get platformIsBrowser => false;
