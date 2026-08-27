/// Web implementation of the runtime config lookup.
///
/// Reads the `window.NYAYA_API_BASE_URL` global that `web/config.js` sets
/// before the Flutter bootstrap runs.
library;

// dart:js_interop is the correct dependency here: this file is only ever
// compiled for the web, selected by the conditional export in
// runtime_config.dart. Non-web builds get runtime_config_stub.dart instead.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// The raw global. Typed as [JSAny] rather than [String] on purpose: if
/// `config.js` fails to load, or is cached as an older version that never set
/// the global, this is `undefined` rather than a string. Reading it as a
/// loosely typed value and checking the type ourselves keeps that case a clean
/// null instead of a cast error at startup.
@JS('NYAYA_API_BASE_URL')
external JSAny? get _nyayaApiBaseUrl;

/// The runtime backend override, or null if it is absent, blank, or not a
/// string. Blank is treated as absent so `config.js` can deliberately opt out
/// on localhost and let the dart-define take over for local development.
String? runtimeApiBaseUrl() {
  final raw = _nyayaApiBaseUrl;
  if (raw == null || !raw.isA<JSString>()) return null;
  final value = (raw as JSString).toDart.trim();
  return value.isEmpty ? null : value;
}
