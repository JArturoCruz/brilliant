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

For the Android Studio emulator, `localhost` (or `127.0.0.1`) is translated to
`10.0.2.2`, the emulator's route to the host computer. On a physical phone or a
different computer, set `BRILLIANT_API_URL` to the server's stable LAN DNS
name, for example `http://brilliant-server.local:3000`. The hostname must be
configured in the network's DNS/mDNS; the project name alone is not a network
address. Local HTTP is enabled only in Android debug builds.

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
