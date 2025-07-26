import 'dart:async';
import 'package:js/js.dart';


@JS()
@anonymous
class PromiseJsImpl<T> {
  external PromiseJsImpl(Function executor);
  external PromiseJsImpl then([Function? onFulfilled, Function? onRejected]);
  external PromiseJsImpl catchError(Function onRejected);
}

Future<T> handleThenable<T>(PromiseJsImpl<T> promise) {
  final completer = Completer<T>();
  promise.then(allowInterop((value) {
    completer.complete(value);
  }), allowInterop((error) {
    completer.completeError(error);
  }));
  return completer.future;
}

dynamic dartify(dynamic jsObject) {
  if (jsObject == null) return null;
  if (jsObject is List) {
    return jsObject.map(dartify).toList();
  }
  if (jsObject is Map) {
    final jsMap = {};
    jsObject.forEach((key, value) {
      jsMap[dartify(key)] = dartify(value);
    });
    return jsMap;
  }
  return jsObject;
}

@JS('jsify')
external dynamic get jsifyFunction;

dynamic jsify(dynamic dartObject, [dynamic Function(dynamic)? customJsify]) {
  if (dartObject == null) return null;
  if (customJsify != null) {
    final result = customJsify(dartObject);
    if (result != null) return result;
  }
  if (dartObject is List) {
    return dartObject.map((e) => jsify(e, customJsify)).toList();
  }
  if (dartObject is Map) {
    final jsObject = {};
    dartObject.forEach((key, value) {
      jsObject[jsify(key, customJsify)] = jsify(value, customJsify);
    });
    return jsObject;
  }
  return dartObject;
}

// Export the functions for use in other files
@JS('handleThenable')
external dynamic get handleThenableFunction;

@JS('dartify')
external dynamic get dartifyFunction; 