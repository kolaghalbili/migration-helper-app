// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebStorage {
  static String get(String key, {String defaultValue = ''}) =>
      html.window.localStorage[key] ?? defaultValue;
}
