/// Non-web implementation of the runtime config lookup.
///
/// Android, iOS, and desktop builds have no `window` object and no
/// `config.js`, so there is never a runtime override to report. Returning null
/// makes `ApiClient` fall through to the `API_BASE_URL` dart-define.
library;

/// Always null off the web: nothing can override the compile-time value.
String? runtimeApiBaseUrl() => null;
