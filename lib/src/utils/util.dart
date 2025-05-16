import 'package:html/dom.dart';

extension GetMethod on Map {
  String? get(dynamic key) {
    if (!containsKey(key) || this[key] == null) return null;
    var value = this[key];
    if (value is List) return value.isNotEmpty ? value.first.toString() : null;
    return value.toString();
  }

  dynamic getDynamic(dynamic key) {
    return this[key];
  }
}

String? getDomain(String url) {
  try {
    return Uri.parse(url).host.toString().split('.')[0];
  } catch (e) {
    return null;
  }
}

String? getProperty(
  Document? document, {
  String tag = 'meta',
  String attribute = 'property',
  String? property,
  String key = 'content',
}) {
  if (document == null || property == null) return null;

  try {
    return document
        .getElementsByTagName(tag)
        .cast<Element?>()
        .firstWhere((element) => element?.attributes[attribute] == property,
            orElse: () => null)
        ?.attributes[key];
  } catch (e) {
    return null;
  }
}
