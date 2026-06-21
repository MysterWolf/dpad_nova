# DPad Nova — Claude Context
**Last updated:** June 2026
**Version:** 1.0.0+1

## What This Is
A clean, minimal Samsung Tizen TV remote for Android. Connects over local WiFi via the Samsung SmartThings local WebSocket API. Variant of DPad Pilot (github.com/MysterWolf/dpad_pilot) — same UI structure, same architecture, different protocol layer. No ads, no account, no subscription.

## Current Status
- **Live:** In development. Not yet on Play Store.
- **Version:** 1.0.0+1
- **Platform:** Android only

## Tech Stack
| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Flutter 3.x | Android only |
| WebSocket | web_socket_channel | SmartThings local API on :8002 |
| Discovery | HTTP probe port 8001 | Manual IP primary; REST probe confirms Samsung TV |
| Persistence | shared_preferences | Auth token + saved devices |
| State | Riverpod (.family) | Per-IP RemoteNotifier |
| Icons | flutter_launcher_icons | Adaptive, #1e1e2e bg |
| HTTP | http | REST probe only |

## Directory Structure
```
lib/
  models/         saved_device.dart, samsung_device.dart
  services/       samsung_service.dart, discovery_service.dart, saved_devices_service.dart
  providers/      discovery_provider.dart, remote_provider.dart, saved_devices_provider.dart
  screens/        splash_screen.dart, discovery_screen.dart, remote_screen.dart, about_screen.dart
  widgets/        remote_button.dart
assets/
  DPad-Nova.png
  mws_mark_dark.png
```

## Key Files
| File | Purpose |
|------|---------|
| lib/services/samsung_service.dart | Core WebSocket service. Manages connection, auth token, key events. |
| lib/services/discovery_service.dart | REST probe on port 8001 to confirm Samsung TV before WebSocket attempt. |
| lib/providers/remote_provider.dart | Riverpod .family per IP. Wraps SamsungService. Auto-reconnect guard lives here. |
| lib/screens/remote_screen.dart | Main remote UI. SamsungKey + SamsungApp constants live here. |
| lib/screens/splash_screen.dart | MWS splash — identical pattern to DPad Pilot. |

## Protocol — Samsung SmartThings Local API

### WebSocket endpoint
```
wss://{ip}:8002/api/v2/channels/samsung.remote.control
```

### Key event format
Every key press is sent as JSON over the WebSocket:
```json
{
  "method": "ms.remote.control",
  "params": {
    "Cmd": "Click",
    "DataOfCmd": "KEY_*",
    "Option": "false",
    "TypeOfRemote": "SendRemoteKey"
  }
}
```
Replace `KEY_*` with the appropriate key code (e.g., `KEY_HOME`, `KEY_VOLUP`).

### Auth token
- On first connection the TV sends back an auth token in the WebSocket handshake response.
- Stored in SharedPreferences under `samsung_token_{ip}`.
- Replayed on every subsequent connection via the `token` query param in the WebSocket URL.
- No re-authorization loop once paired — the token is valid indefinitely until the user revokes it on the TV.

### Discovery
- REST GET `http://{ip}:8001/api/v2/` must return 200 before attempting the WebSocket connection.
- Response contains device name and model — use to set the saved device name.
- Manual IP entry is the primary path; REST probe is the gating check.

## Architecture Decisions
- **Manual IP entry is primary discovery** — Samsung TVs may not reliably broadcast.
- **REST probe before WebSocket** — port 8001 confirms Samsung TV and retrieves device name.
- **Auth token in SharedPreferences** — never hardcoded. Key: `samsung_token_{ip}`.
- **Token replayed on connection** — no re-authorization prompt after first pairing.
- **App launchers use fixed deeplink map** — `SamsungApp` class in `remote_screen.dart`. No runtime app list query.
- **Single saved device fast path** — splash navigates directly to RemoteScreen if exactly 1 device saved.
- **Auto-reconnect fires once** — 3-flag guard identical to DPad Pilot.

## Invariants — Never Change These

1. **Key events as JSON over WebSocket** — always use the exact structure:
   `{method: ms.remote.control, params: {Cmd: Click, DataOfCmd: KEY_*, Option: false, TypeOfRemote: SendRemoteKey}}`

2. **Auth token in SharedPreferences under `samsung_token_{ip}`** — never hardcode a token. Never embed a token in source.

3. **Token replayed on every connection** — pass token as query param on the WebSocket URL after first auth. Never trigger a re-authorization flow if a stored token exists.

4. **Auto-reconnect fires once** — same 3-flag guard as DPad Pilot: `_intentionalDisconnect`, `_reconnecting`, `_didAutoReconnect`. Never loop reconnects.

5. **No hardcoding of any TV model, IP, or app ID** — user enters IP; it is stored in SavedDevice. `SamsungApp` holds fixed Tizen component strings, not IPs.

6. **Discovery REST probe on port 8001** — always probe `http://{ip}:8001/api/v2/` before attempting WebSocket. Do not skip.

7. **App launchers use fixed deeplink map** — `SamsungApp` class in remote_screen.dart. Never add runtime app discovery.

## Key Codes (SamsungKey class)
| Action | Code |
|--------|------|
| Home | KEY_HOME |
| Back | KEY_RETURN |
| D-pad Up/Down/Left/Right | KEY_UP / KEY_DOWN / KEY_LEFT / KEY_RIGHT |
| OK/Enter | KEY_ENTER |
| Volume Up/Down | KEY_VOLUP / KEY_VOLDOWN |
| Mute | KEY_MUTE |
| Channel Up/Down | KEY_CHUP / KEY_CHDOWN |
| Power | KEY_POWER |
| Menu | KEY_MENU |
| Play/Pause | KEY_PLAY |
| Rewind | KEY_REWIND |
| Fast Forward | KEY_FF |
| Source | KEY_SOURCE |

## Relation to DPad Pilot
DPad Nova mirrors DPad Pilot's architecture exactly:
- Same Riverpod .family pattern
- Same single-device fast path in splash
- Same RemoteButton widget
- Same saved device persistence pattern
- Same auto-reconnect guard

Differences:
- SsapService → SamsungService (WebSocket SmartThings API)
- SsdpService → DiscoveryService (REST probe port 8001)
- SSAP pointer socket → WebSocket JSON messages
- Client key → Samsung auth token (SharedPreferences)
- listApps() → fixed SamsungApp deeplink map

## Build
```bash
flutter pub get
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Samsung TV Setup (User Instructions)
Settings → General → External Device Manager → Device Connect Manager → Access Notification: ON

On first connection the TV shows a pairing prompt — accept it. Subsequent connections are silent (token is cached).

## Claude Code Session Starter
"I'm working on DPad Nova — a Flutter Samsung Tizen TV remote via WebSocket at github.com/MysterWolf/dpad_nova. Pull the repo and read CLAUDE.md before making any changes. Respect all invariants — especially the auth token persistence and the key event JSON format. Confirm you understand before I give you the next task."
