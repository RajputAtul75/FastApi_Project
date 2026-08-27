// NyayaAI runtime configuration.
//
// This file is NOT compiled into main.dart.js. Everything in mobile/web/ is
// copied verbatim into build/web/, so after a build you can change the backend
// URL by editing build/web/config.js and redeploying — no Flutter rebuild.
//
// Why this exists: --dart-define values are baked into the JavaScript bundle at
// compile time. A build that forgets the flag silently falls back to
// http://localhost:8000, which in a deployed page means "the visitor's own
// computer" and fails for everyone. This file removes that failure mode.
(function () {
  var host = window.location.hostname;
  var isLocalDev = host === 'localhost' || host === '127.0.0.1' || host === '';

  // Left blank during local development so the API_BASE_URL dart-define (or its
  // http://localhost:8000 default) applies when running `flutter run -d chrome`.
  // Anywhere else — Vercel, or any other host — the deployed backend is used.
  window.NYAYA_API_BASE_URL = isLocalDev
    ? ''
    : 'https://fastapi-project-zv45.onrender.com';
})();
