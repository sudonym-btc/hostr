import 'dart:io';

bool isPlatformSocketException(Object error) => error is SocketException;
