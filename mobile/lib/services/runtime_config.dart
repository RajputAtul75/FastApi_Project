/// Runtime (as opposed to compile-time) configuration lookup.
///
/// Flutter Web bakes `--dart-define` values into `main.dart.js`, which means a
/// deployed bundle can only be repointed at a different backend by recompiling.
/// That is how the production site ended up calling `http://localhost:8000`.
///
/// To avoid repeating that, the web implementation reads a plain JavaScript
/// global (`window.NYAYA_API_BASE_URL`, set by `web/config.js`) that ships
/// alongside the bundle as a separate file. Editing that one file in
/// `build/web/` and redeploying is enough to change backends — no Flutter
/// toolchain required.
///
/// Non-web platforms have no such global, so they get the stub, which returns
/// null and lets the compile-time value win.
library;

export 'runtime_config_stub.dart'
    if (dart.library.js_interop) 'runtime_config_web.dart';
