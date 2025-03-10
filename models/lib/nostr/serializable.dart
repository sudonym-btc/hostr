import 'dart:convert';

abstract class Serializable {
  Map<String, dynamic> toJson();
  static fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  toString() {
    return jsonEncode(toJson());
  }
}
