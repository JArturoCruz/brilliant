# Brilliant

Brilliant is a Flutter game that requires an authenticated account before
opening game content. Account credentials and session tokens are handled by
the independent Brilliant Auth Server.

## Run locally

Start the auth server in one terminal:

```powershell
cd C:\Users\jorge\brilliant-auth-server
npm run dev
```

Start Flutter in another terminal:

```powershell
cd C:\flutter\brilliant
flutter run -d chrome --web-port=61311 --dart-define=BRILLIANT_API_URL=http://localhost:3000
```

The server must allow the exact Chrome origin in `CLIENT_ORIGINS`, for example
`http://localhost:61311`. Restart the server after changing `.env`.

## Multiplayer

Sign in and choose **Multijugador** from the start screen. Create a room or
enter an invitation code; the host starts when 2–6 players are connected. The
host selects the board map. Room state, dice, legal moves, scores, and the win
condition are validated by the authenticated server. Players can leave at any
time; leaving or failing to reconnect within 60 seconds concedes the game. A
host leaving before the start closes the room, while leaving during a game
awards the win to the remaining players.

The client polls every two seconds and automatically retries after a network
interruption. Multiplayer rooms currently live in server memory: restarting
the server closes active rooms, and multiplayer requires a single server
instance.

Each player configures and plays on a separate board using the original game
interface and map rules. Players take turns with the same pair of dice for
each round; the server validates every move and keeps each board private to
its player.

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
