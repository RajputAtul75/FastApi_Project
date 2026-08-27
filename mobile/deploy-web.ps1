# NyayaAI - build and stage the Flutter web bundle for the Vercel deploy.
#
#   powershell -ExecutionPolicy Bypass -File mobile\deploy-web.ps1
#   ...\deploy-web.ps1 -SkipBuild            # re-stage only, no 2-minute rebuild
#   ...\deploy-web.ps1 -ForceUnlock          # clear a stale .git\index.lock first
#   ...\deploy-web.ps1 -ApiBaseUrl https://other-backend.onrender.com
#
# This exists because the deployed site once shipped pointing at
# http://localhost:8000 - a build made without --dart-define. In a deployed page
# "localhost" means the VISITOR's machine, so the app failed for everyone while
# looking perfectly fine locally. Every check below verifies an actual property
# of the build output rather than trusting that a flag was passed.

#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ApiBaseUrl = 'https://fastapi-project-zv45.onrender.com',
    [switch]$SkipBuild,
    [switch]$ForceUnlock
)

# Deliberately NOT 'Stop'. PowerShell 5.1 turns anything a native .exe writes to
# stderr into an error record, and with -ErrorActionPreference Stop that becomes
# a terminating error. git writes plenty of harmless chatter to stderr, so Stop
# made the script die mid-staging with a wall of RemoteException noise. Exit
# codes are checked explicitly instead.
$ErrorActionPreference = 'Continue'

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  OK   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  WARN $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host "`n  FAIL $msg" -ForegroundColor Red; exit 1 }

# Runs git and reports success by exit code, not by whether it printed to stderr.
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git @GitArgs 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    return ($LASTEXITCODE -eq 0)
}

$mobileDir = $PSScriptRoot
$repoRoot  = Split-Path $mobileDir -Parent
$webOut    = Join-Path $mobileDir 'build\web'
Set-Location $mobileDir

if ($ApiBaseUrl -notmatch '^https?://') {
    Die "-ApiBaseUrl must start with http:// or https:// (got '$ApiBaseUrl'). A bare host parses as a relative URL, so requests would hit the Vercel site instead of the backend."
}
$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')

Step 'Backend URL for this build'
Write-Host "  $ApiBaseUrl"

# --- Stale git lock -----------------------------------------------------------
# On this repo the usual culprits are OneDrive syncing .git, VS Code's git
# integration, or a git process that died mid-command. A zero-byte index.lock
# with no git process running is stale and safe to delete.
$lockFile = Join-Path $repoRoot '.git\index.lock'
if (Test-Path $lockFile) {
    Step 'Stale git lock detected'
    $running = @(Get-Process -Name git -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        Die "$($running.Count) git process(es) are running, so the lock is real. Close any editor or git GUI, wait for them to exit, then re-run."
    }
    Write-Host "  Found $lockFile with no git process running."
    if ($ForceUnlock) {
        Remove-Item -Force $lockFile
        Ok 'stale lock removed'
    } else {
        Die "Stale lock. Close VS Code and pause OneDrive sync, then re-run with -ForceUnlock (add -SkipBuild to avoid rebuilding)."
    }
}

# --- Build -------------------------------------------------------------------
if ($SkipBuild) {
    Step 'Skipping build (-SkipBuild); verifying existing output'
    if (-not (Test-Path (Join-Path $webOut 'main.dart.js'))) {
        Die 'No existing build to verify. Re-run without -SkipBuild.'
    }
} else {
    Step 'flutter pub get'
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { Die 'pub get failed.' }

    Step 'flutter analyze'
    & flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Warn 'analyze reported problems (see above). Check whether any are errors before shipping.'
    } else {
        Ok 'no analyzer complaints'
    }

    Step 'flutter build web'
    # --pwa-strategy=none stops the service worker precaching every file in
    # build/web cache-first, which would defeat config.js edits and the
    # no-store header. The flag is deprecated (flutter/flutter#156910) and will
    # eventually be removed, so fall back gracefully and rely on the service
    # worker check below to catch any behaviour change.
    & flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=$ApiBaseUrl
    if ($LASTEXITCODE -ne 0) {
        Warn '--pwa-strategy may have been removed from this Flutter version; retrying without it.'
        & flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl
        if ($LASTEXITCODE -ne 0) { Die 'build failed.' }
    }
}

# --- Verify the output -------------------------------------------------------
Step 'Verifying the built bundle'

$bundle = Join-Path $webOut 'main.dart.js'
if (-not (Test-Path $bundle)) { Die "main.dart.js missing at $bundle" }

# The positive check is the trustworthy one: the URL must actually be in there.
if (Select-String -Path $bundle -Pattern $ApiBaseUrl -SimpleMatch -Quiet) {
    Ok 'backend URL is baked into main.dart.js'
} else {
    Die "main.dart.js does NOT contain $ApiBaseUrl - the dart-define did not take effect. Do not deploy this."
}

if (Select-String -Path $bundle -Pattern 'http://localhost:8000' -SimpleMatch -Quiet) {
    Warn 'main.dart.js still contains http://localhost:8000. Harmless given the check above passed, but worth a glance.'
}

$cfg = Join-Path $webOut 'config.js'
if (-not (Test-Path $cfg)) { Die 'build/web/config.js is missing; it should be copied from mobile/web/config.js by the build.' }
if (Select-String -Path $cfg -Pattern $ApiBaseUrl -SimpleMatch -Quiet) {
    Ok 'config.js carries the same backend URL'
} else {
    Warn "config.js does not mention $ApiBaseUrl. The runtime override wins over the dart-define, so the deployed site will use whatever URL is in there - update mobile/web/config.js."
}

# Verify the property, not the flag: if a future Flutter precaches config.js,
# hand-edits to it would stop taking effect for returning visitors.
$sw = Join-Path $webOut 'flutter_service_worker.js'
if ((Test-Path $sw) -and (Select-String -Path $sw -Pattern 'config.js' -SimpleMatch -Quiet)) {
    Warn 'The service worker precaches config.js, so post-build edits to it will not reach returning visitors. The dart-define still applies, so this is not fatal.'
} else {
    Ok 'service worker does not precache config.js'
}

# --- Stage -------------------------------------------------------------------
Step 'Staging for git'
# mobile/.gitignore contains "/build/", so files under build/ are ignored.
# Already-tracked ones commit fine as modifications, but NEW files - notably
# config.js - are silently skipped without -f, which would 404 on Vercel and
# send the app straight back to the localhost fallback.
if (-not (Invoke-Git add -u .)) { Die 'git add -u failed.' }

$newFiles = @(
    'web/config.js', 'vercel.json', 'web/index.html', 'deploy-web.ps1',
    'lib/services/runtime_config.dart',
    'lib/services/runtime_config_stub.dart',
    'lib/services/runtime_config_web.dart'
) | Where-Object { Test-Path (Join-Path $mobileDir $_) }
if (-not (Invoke-Git add -- @newFiles)) { Die 'staging the new source files failed.' }

if (-not (Invoke-Git add -f build/web/config.js)) { Die 'git add -f build/web/config.js failed.' }

& git ls-files --error-unmatch build/web/config.js *> $null
if ($LASTEXITCODE -ne 0) {
    Die 'build/web/config.js is STILL not tracked. Vercel serves only committed files, so it would 404 and the app would fall back to localhost. Do not push.'
}
Ok 'build/web/config.js is tracked and will deploy'

Step 'Next steps'
Write-Host @"
  Vercel is Git-connected, so pushing to main IS the deploy:

    git commit -m "Point deployed web build at the Render backend"
    git push

  Then, on the live site:
    1. Hard-reload (Ctrl+Shift+R) to drop the old cached bundle.
    2. Confirm https://<your-site>/config.js returns JavaScript, not a 404.
    3. DevTools > Network: requests must go to $ApiBaseUrl/api/...
       and NOT to localhost:8000.
    4. Warm the backend before demoing - Render's free tier sleeps after
       ~15 min idle and takes 30-60s to wake. Open
       $ApiBaseUrl/api/health and wait for JSON first.
"@
