# mali_app

Flutter mobile client for Mali.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (SDK `^3.11.0` per `pubspec.yaml`)
- A running Mali API (see [Docker backend](#docker-backend) below)
- For Android: emulator or physical device with USB debugging

## Docker backend

Start Postgres, Redis, and the API from the **repository root**:

```powershell
cd f:\Sources\Mali
docker compose up -d
```

The API is exposed on the host at **http://localhost:8082** (see `docker-compose.override.yml` for port mappings).

## Install dependencies

```powershell
cd f:\Sources\Mali\mali_app
flutter pub get
```

## API base URL

The app reads `MALI_API_BASE_URL` at compile time (`lib/core/config/api_config.dart`).

**Default (unset):** `https://mali-api.nlisimalaba.co.zw` (production).

| Where the app runs | Host to use | Example |
| --- | --- | --- |
| Production / release APK | Live API | `https://mali-api.nlisimalaba.co.zw` |
| Android emulator + local Docker | `10.0.2.2` (alias for your PC) | `http://10.0.2.2:8082` |
| iOS Simulator (macOS) + local Docker | `localhost` | `http://localhost:8082` |
| Physical phone (same Wi‑Fi as PC) | Your PC’s LAN IP | `http://192.168.1.50:8082` |

Release APK (uses production default):

```powershell
flutter build apk --release
```

Local Docker override:

```powershell
flutter run --dart-define=MALI_API_BASE_URL=http://10.0.2.2:8082
```

## Run on mobile

List connected devices:

```powershell
flutter devices
```

### Android emulator

```powershell
cd f:\Sources\Mali\mali_app
flutter run -d emulator-5556 --dart-define=MALI_API_BASE_URL=http://10.0.2.2:8082
```

If only one device is connected, omit `-d`:

```powershell
flutter run --dart-define=MALI_API_BASE_URL=http://10.0.2.2:8082
```

### Physical Android (USB)

1. Enable USB debugging on the device.
2. Replace `YOUR_PC_IP` with your machine’s address on the LAN (same network as the phone).

```powershell
flutter run --dart-define=MALI_API_BASE_URL=http://YOUR_PC_IP:8082
```

### iOS (macOS only)

Simulator:

```powershell
flutter run --dart-define=MALI_API_BASE_URL=http://localhost:8082
```

Physical iPhone: use your Mac’s LAN IP, same as physical Android.

## Other targets (optional)

**Windows desktop:**

```powershell
flutter run -d windows --dart-define=MALI_API_BASE_URL=http://localhost:8082
```

**Chrome:**

```powershell
flutter run -d chrome --dart-define=MALI_API_BASE_URL=http://localhost:8082
```

## While the app is running

| Key | Action |
| --- | --- |
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |

## Code generation

After changing Riverpod or Drift annotations:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

- **Connection errors on login/register:** Confirm `docker compose ps` shows `mali_api` up and try opening `http://localhost:8082/health` in a browser on your PC.
- **Emulator cannot reach API:** Use `10.0.2.2`, not `localhost`.
- **Physical device cannot reach API:** Use your PC’s LAN IP; ensure port `8082` is not blocked by the firewall.
- **HTTP blocked on Android:** Debug builds allow cleartext traffic via `android/app/src/debug/AndroidManifest.xml`.
