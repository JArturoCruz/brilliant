# Brilliant

Brilliant is a Flutter game that requires an authenticated account before
opening game content. Account credentials and session tokens are handled by
the independent Brilliant Auth Server.

## Run locally

Start the auth server in one terminal:

```powershell
cd C:\flutter\server\brilliant-auth-server
npm run dev
```

Start Flutter in another terminal:

```powershell
cd C:\flutter\brilliant
flutter run -d chrome --dart-define=BRILLIANT_API_URL=http://localhost:3000
```

When Chrome serves the app from the same computer as the server, it derives
the API hostname from the page's hostname and uses port 3000. You can omit
`--dart-define` in this local setup.

For the Android Studio emulator, the default `localhost` (or `127.0.0.1`) is
translated to `10.0.2.2`, the emulator's route to the host computer. On a
physical phone or another computer, select or enter the server address on the
start screen. A DNS name such as `brilliant-server.local` must be configured
in the network's DNS/mDNS; the project name alone is not a network address.
Local HTTP is enabled only in Android debug builds.

To build a debug APK for a physical Android phone on the same private Wi-Fi:

```powershell
flutter build apk --debug --split-per-abi
```

For most phones, install `build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk`.
Use `app-armeabi-v7a-debug.apk` only for older 32-bit phones. On the start
screen, choose a detected server or enter its IP and port and press
**Conectar**. The address is remembered; if the server IP changes, search again
or enter the new address. Switching addresses clears the local session, so sign
in again. Select only servers you trust: discovery and the health check do not
authenticate the server.

Automatic discovery uses UDP broadcast on port 38971 and works only on the
same local network when broadcasts are allowed. The server must be updated and
restarted with the discovery changes. Allow inbound UDP 38971 on the server's
private firewall profile in addition to TCP 3000. Guest networks, VPNs and
client isolation may prevent discovery. Web browsers cannot perform UDP
discovery; enter the address manually and configure the server's CORS origins.
On iOS, allow access to the local network when prompted.

The server must be running and listening on the network. Set its
`BETTER_AUTH_URL` in the server `.env` to the same LAN URL, then restart it.
Connect the phone to the same Wi-Fi. On Windows, set that network's profile to
**Private**, then run this in PowerShell as Administrator to allow only local
subnet devices to connect:

```powershell
New-NetFirewallRule -DisplayName "Brilliant Auth Server LAN (Private)" -Direction Inbound -Protocol TCP -LocalPort 3000 -RemoteAddress LocalSubnet -Action Allow -Profile Private
New-NetFirewallRule -DisplayName "Brilliant Discovery LAN (Private)" -Direction Inbound -Protocol UDP -LocalPort 38971 -RemoteAddress LocalSubnet -Action Allow -Profile Private
```

Do not expose the development HTTP server on a Public network or the Internet.

For a release APK, use the server's deployed HTTPS URL (either enter it at
startup or specify a default at build time):

```powershell
flutter build apk --release --dart-define=BRILLIANT_API_URL=https://your-auth-domain.example
```

Release builds reject HTTP, including the HTTP addresses announced by local
discovery. Use a valid HTTPS hostname and certificate in production. This project currently uses the Android debug
signing key for release builds, which is suitable only for local sideload
testing, not for publishing or secure long-term updates.

Chrome local is allowed on any Flutter development port. If you host the web
app under a non-local hostname, add its exact origin to `CLIENT_ORIGINS` in the
server configuration. For access outside the local network, deploy the server
behind HTTPS and use its stable domain.

## Multiplayer

Sign in and choose **Multijugador** from the start screen. Create a room or
enter an invitation code; the host starts when 2–6 players are connected. The
host selects the board map. Room state, dice, legal moves, scores, and the win
condition are validated by the authenticated server. Players can leave at any
time. If the host leaves before or during initial setup, the room closes and
everyone returns to the lobby. Once play begins, a leaving or disconnected
player is removed while the game continues; their score and already-claimed
region rewards are preserved.

The client polls every two seconds and automatically retries after a network
interruption. Multiplayer rooms currently live in server memory: restarting
the server closes active rooms, and multiplayer requires a single server
instance.

Each player configures and plays on a separate board using the original game
interface and map rules. Everyone plays each round with the same pair of dice
at the same time; the next pair is rolled only after all players complete or
skip that round. The server validates every move and keeps each board private
to its player. Players who complete the same region during one round share
that round's reward; the next reward remains for the next round in which
someone completes it. Claimed rewards remain unavailable if a player concedes.

## Authentication and privacy

- Playing and viewing game instructions require an active session.
- Session tokens are stored with `flutter_secure_storage`; sign-out also clears
  the local token when the server cannot be reached.
- Usernames are trimmed and compared case-insensitively with Unicode
  normalization. The server enforces uniqueness in SQLite.
- Sign-in is limited to 8 attempts per 15 minutes and registration to 5 attempts
  per hour, per client address resolved by Better Auth. If deployed behind a
  reverse proxy, configure trusted proxy addresses before relying on IP-based
  limits. The in-memory limit store resets on restart and is for one server
  instance.
- Requests carry a random reference ID. If an error includes a reference code,
  share that code with support to find its server log entry.
- Diagnostic logs include only the request ID, known auth endpoint, method,
  status, and duration. They do not include passwords, tokens, email addresses,
  usernames, request bodies, or client IP addresses. The client emits detailed
  request diagnostics only in debug builds.
- The app does not collect gameplay analytics or use the diagnostics as user
  activity tracking.
- Production builds must use HTTPS. Keep `BETTER_AUTH_SECRET` outside source
  control and rotate it if it may have been exposed.
