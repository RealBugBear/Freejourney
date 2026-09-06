# Sentry Setup — Reflex Journey

The app already ships with a privacy-conscious Sentry integration (`lib/core/monitoring/sentry_service.dart`). It activates **only** when `SENTRY_DSN` is set in the bundled env file.

## 1. Create the Sentry project (~5 min)

1. Go to [sentry.io](https://sentry.io) and sign in (or create an account).
2. Create an **organization** — on first setup choose **Data Storage Location: European Union (EU)**. This cannot be changed later.
3. **Create project** → platform **Flutter**.
4. Copy the **DSN** (Client Keys). EU projects use a host like `*.ingest.de.sentry.io`.

## 2. Add the DSN locally

Edit `.env.prod` (gitignored — never commit the real DSN):

```env
SENTRY_DSN=https://YOUR_PUBLIC_KEY@oXXXX.ingest.de.sentry.io/YYYY
```

For a one-off local test before rebuilding production, you can temporarily paste the same line into `.env.dev` — remove it afterward so dev builds stay quiet.

Both `.env.dev` and `.env.prod` are bundled via `pubspec.yaml`; production/TestFlight builds read `.env.prod`.

## 3. Rebuild and install

```bash
make bump-build
make testflight          # TestFlight
# or cable install:
flutter run --profile --flavor production -d YOUR_DEVICE_ID -t lib/main_production.dart
```

## 4. Verify

**Option A — Dev Tools (internal testers only, `@reflexjourney.de`):**

Settings → Dev Tools → **Test-Crash an Sentry senden**

Status line should show `Sentry: aktiv`.

**Option B — Dashboard:**

Within ~30 seconds an issue should appear in Sentry → Issues. Open the event JSON and confirm:

- Error type + stacktrace present
- No email, username, journal text, or URLs in extras
- Release tag like `reflexjourney@1.0.5+2026083102`

## Privacy defaults (already configured)

| Setting | Value |
|---------|-------|
| `sendDefaultPii` | `false` |
| Performance tracing | off (`tracesSampleRate = 0`) |
| Screenshots / view hierarchy | off |
| HTTP / navigation breadcrumbs | dropped |
| Events with request context | dropped entirely |
| Logger messages with user data | never sent — only `Object` + `StackTrace` |

## Beta testers

Production builds with `SENTRY_DSN` in `.env.prod` report crashes automatically — testers do not need to do anything. Match feedback form entries to Sentry issues via device/time or your tester ID field.
